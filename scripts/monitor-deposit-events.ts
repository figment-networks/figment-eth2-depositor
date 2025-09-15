import { network } from "hardhat";
import { parseAbiItem, decodeEventLog, Address, Log } from "viem";

// Ethereum 2.0 Deposit Contract address (mainnet)
const ETH2_DEPOSIT_CONTRACT_MAINNET = "0x00000000219ab540356cBB839Cbe05303d7705Fa";

// For testing, you might want to use your deployed mock contract instead
// const DEPOSIT_CONTRACT_ADDRESS = "0x..."; // Your mock contract address

// Event signature for the DepositEvent from the deposit contract
const DEPOSIT_EVENT_ABI = parseAbiItem("event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index)");

interface ParsedDepositEvent {
  pubkey: string;
  withdrawal_credentials: string;
  amount: bigint; // Amount in gwei
  signature: string;
  index: bigint;
  blockNumber: bigint;
  transactionHash: string;
  logIndex: number;
}

async function parseDepositEvent(log: Log): Promise<ParsedDepositEvent> {
  try {
    const decoded = decodeEventLog({
      abi: [DEPOSIT_EVENT_ABI],
      data: log.data,
      topics: log.topics,
    });

    // Parse the amount from bytes to gwei (little endian 64-bit)
    const amountBytes = decoded.args.amount as `0x${string}`;
    const amountGwei = BigInt("0x" + amountBytes.slice(2).match(/.{2}/g)?.reverse().join("") || "0");

    // Parse the index from bytes (little endian 64-bit)
    const indexBytes = decoded.args.index as `0x${string}`;
    const index = BigInt("0x" + indexBytes.slice(2).match(/.{2}/g)?.reverse().join("") || "0");

    return {
      pubkey: decoded.args.pubkey as string,
      withdrawal_credentials: decoded.args.withdrawal_credentials as string,
      amount: amountGwei,
      signature: decoded.args.signature as string,
      index,
      blockNumber: log.blockNumber || 0n,
      transactionHash: log.transactionHash || "",
      logIndex: log.logIndex || 0,
    };
  } catch (error) {
    console.error("Error parsing deposit event:", error);
    throw error;
  }
}

function formatDepositEvent(event: ParsedDepositEvent): void {
  console.log("🔸 New Deposit Event");
  console.log("─".repeat(50));
  console.log(`Block:      ${event.blockNumber}`);
  console.log(`Tx Hash:    ${event.transactionHash}`);
  console.log(`Log Index:  ${event.logIndex}`);
  console.log(`Validator Index: ${event.index}`);
  console.log(`Amount:     ${event.amount} gwei (${Number(event.amount) / 1e9} ETH)`);
  console.log(`Pubkey:     ${event.pubkey}`);
  console.log(`Withdrawal: ${event.withdrawal_credentials}`);
  console.log(`Signature:  ${event.signature.slice(0, 20)}...${event.signature.slice(-20)}`);
  console.log("─".repeat(50));
  console.log("");
}

async function monitorDepositEvents(
  depositContractAddress: Address,
  figmentContractAddress?: Address,
  fromBlock: bigint = 0n
) {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  console.log("🔍 Starting Deposit Event Monitor");
  console.log("═".repeat(60));
  console.log(`Deposit Contract: ${depositContractAddress}`);
  if (figmentContractAddress) {
    console.log(`Filtering for Figment Contract: ${figmentContractAddress}`);
  }
  console.log(`Starting from block: ${fromBlock}`);
  console.log("═".repeat(60));
  console.log("");

  // Get historical events first
  console.log("📜 Fetching historical events...");

  try {
    const logs = await publicClient.getLogs({
      address: depositContractAddress,
      event: DEPOSIT_EVENT_ABI,
      fromBlock,
      toBlock: "latest",
    });

    console.log(`Found ${logs.length} historical deposit events`);
    console.log("");

    for (const log of logs) {
      // If filtering by Figment contract, check if the transaction was sent by it
      if (figmentContractAddress) {
        const tx = await publicClient.getTransaction({ hash: log.transactionHash! });
        if (tx.to?.toLowerCase() !== figmentContractAddress.toLowerCase()) {
          continue; // Skip events not from our contract
        }
      }

      const parsedEvent = await parseDepositEvent(log);
      formatDepositEvent(parsedEvent);
    }

    // Set up real-time monitoring
    console.log("⏱️  Setting up real-time event monitoring...");
    console.log("Press Ctrl+C to stop monitoring");
    console.log("");

    // Watch for new events
    const unwatch = publicClient.watchEvent({
      address: depositContractAddress,
      event: DEPOSIT_EVENT_ABI,
      onLogs: async (logs) => {
        for (const log of logs) {
          // If filtering by Figment contract, check if the transaction was sent by it
          if (figmentContractAddress) {
            try {
              const tx = await publicClient.getTransaction({ hash: log.transactionHash! });
              if (tx.to?.toLowerCase() !== figmentContractAddress.toLowerCase()) {
                continue; // Skip events not from our contract
              }
            } catch (error) {
              console.error("Error fetching transaction:", error);
              continue;
            }
          }

          const parsedEvent = await parseDepositEvent(log);
          console.log("🔥 REAL-TIME EVENT:");
          formatDepositEvent(parsedEvent);
        }
      },
    });

    // Handle graceful shutdown
    process.on("SIGINT", () => {
      console.log("\n\n🛑 Stopping event monitor...");
      unwatch();
      process.exit(0);
    });

    // Keep the process alive
    await new Promise(() => {}); // This will run indefinitely until SIGINT

  } catch (error) {
    console.error("Error monitoring deposit events:", error);
    throw error;
  }
}

async function main() {
  const args = process.argv.slice(2);

  // Parse command line arguments
  const depositContractArg = args.find(arg => arg.startsWith("--deposit-contract="));
  const figmentContractArg = args.find(arg => arg.startsWith("--figment-contract="));
  const fromBlockArg = args.find(arg => arg.startsWith("--from-block="));

  const depositContract = depositContractArg
    ? depositContractArg.split("=")[1] as Address
    : ETH2_DEPOSIT_CONTRACT_MAINNET as Address;

  const figmentContract = figmentContractArg
    ? figmentContractArg.split("=")[1] as Address
    : undefined;

  const fromBlock = fromBlockArg
    ? BigInt(fromBlockArg.split("=")[1])
    : BigInt(0);

  if (args.includes("--help") || args.includes("-h")) {
    console.log("📖 Deposit Event Monitor Usage:");
    console.log("");
    console.log("npx hardhat run scripts/monitor-deposit-events.ts [options]");
    console.log("");
    console.log("Options:");
    console.log("  --deposit-contract=ADDRESS   Deposit contract address to monitor");
    console.log("                               (default: mainnet deposit contract)");
    console.log("  --figment-contract=ADDRESS   Filter events only from this contract");
    console.log("  --from-block=NUMBER          Start monitoring from this block");
    console.log("                               (default: 0)");
    console.log("  --help, -h                   Show this help message");
    console.log("");
    console.log("Examples:");
    console.log("  # Monitor all deposit events from mainnet deposit contract");
    console.log("  npx hardhat run scripts/monitor-deposit-events.ts");
    console.log("");
    console.log("  # Monitor only events from your Figment contract");
    console.log("  npx hardhat run scripts/monitor-deposit-events.ts \\");
    console.log("    --figment-contract=0x123... \\");
    console.log("    --from-block=19000000");
    console.log("");
    console.log("  # Monitor mock contract for testing");
    console.log("  npx hardhat run scripts/monitor-deposit-events.ts \\");
    console.log("    --deposit-contract=0x456... \\");
    console.log("    --figment-contract=0x789...");
    return;
  }

  await monitorDepositEvents(depositContract, figmentContract, fromBlock);
}

// Export for potential use in other scripts
export {
  monitorDepositEvents,
  parseDepositEvent,
  formatDepositEvent,
  DEPOSIT_EVENT_ABI,
  ETH2_DEPOSIT_CONTRACT_MAINNET,
};

// Run if called directly
const isMainModule = import.meta.url.endsWith(process.argv[1]);
if (isMainModule) {
  main().catch((error) => {
    console.error("❌ Script failed:", error);
    process.exitCode = 1;
  });
}
