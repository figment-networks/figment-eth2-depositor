import { network } from "hardhat";
import { parseAbiItem, decodeEventLog, Address } from "viem";

// Event signature for the DepositEvent from the deposit contract
const DEPOSIT_EVENT_ABI = parseAbiItem("event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index)");

async function checkTransactionEvents(txHash: string) {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  console.log("🔍 Checking Deposit Events for Transaction");
  console.log("═".repeat(60));
  console.log(`Transaction Hash: ${txHash}`);
  console.log("═".repeat(60));
  console.log("");

  try {
    // Get the transaction receipt
    const receipt = await publicClient.getTransactionReceipt({ hash: txHash as `0x${string}` });

    console.log(`✅ Transaction found in block ${receipt.blockNumber}`);
    console.log(`Gas used: ${receipt.gasUsed.toLocaleString()}`);
    console.log(`Status: ${receipt.status === 'success' ? '✅ Success' : '❌ Failed'}`);
    console.log("");

    // Filter logs for DepositEvent
    const depositEvents = receipt.logs.filter(log => {
      try {
        // Try to decode as DepositEvent
        decodeEventLog({
          abi: [DEPOSIT_EVENT_ABI],
          data: log.data,
          topics: log.topics,
        });
        return true;
      } catch {
        return false;
      }
    });

    console.log(`📊 Found ${depositEvents.length} deposit events`);
    console.log("");

    // Parse and display each deposit event
    for (let i = 0; i < depositEvents.length; i++) {
      const log = depositEvents[i];

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

        console.log(`🔸 Deposit Event #${i + 1}`);
        console.log("─".repeat(40));
        console.log(`Contract:   ${log.address}`);
        console.log(`Log Index:  ${log.logIndex}`);
        console.log(`Validator Index: ${index}`);
        console.log(`Amount:     ${amountGwei} gwei (${Number(amountGwei) / 1e9} ETH)`);
        console.log(`Pubkey:     ${decoded.args.pubkey}`);
        console.log(`Withdrawal: ${decoded.args.withdrawal_credentials}`);
        console.log(`Signature:  ${(decoded.args.signature as string).slice(0, 20)}...${(decoded.args.signature as string).slice(-20)}`);
        console.log("─".repeat(40));
        console.log("");

      } catch (error) {
        console.error(`❌ Error parsing deposit event #${i + 1}:`, error);
      }
    }

    // Also check for your contract's DepositEvent
    const figmentDepositEventAbi = parseAbiItem("event DepositEvent(address from, uint256 nodesAmount, uint256 totalAmount)");

    const figmentEvents = receipt.logs.filter(log => {
      try {
        decodeEventLog({
          abi: [figmentDepositEventAbi],
          data: log.data,
          topics: log.topics,
        });
        return true;
      } catch {
        return false;
      }
    });

    if (figmentEvents.length > 0) {
      console.log(`📊 Found ${figmentEvents.length} Figment contract events`);
      console.log("");

      figmentEvents.forEach((log, i) => {
        try {
          const decoded = decodeEventLog({
            abi: [figmentDepositEventAbi],
            data: log.data,
            topics: log.topics,
          });

          console.log(`🔸 Figment Event #${i + 1}`);
          console.log("─".repeat(40));
          console.log(`Contract:    ${log.address}`);
          console.log(`From:        ${decoded.args.from}`);
          console.log(`Nodes:       ${decoded.args.nodesAmount}`);
          console.log(`Total:       ${decoded.args.totalAmount} wei (${Number(decoded.args.totalAmount) / 1e18} ETH)`);
          console.log("─".repeat(40));
          console.log("");

        } catch (error) {
          console.error(`❌ Error parsing Figment event #${i + 1}:`, error);
        }
      });
    }

  } catch (error) {
    console.error("❌ Error checking transaction:", error);
    throw error;
  }
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    console.log("📖 Transaction Event Checker Usage:");
    console.log("");
    console.log("npx hardhat run scripts/check-transaction-events.ts <tx_hash>");
    console.log("");
    console.log("Arguments:");
    console.log("  tx_hash     Transaction hash to check for deposit events");
    console.log("");
    console.log("Examples:");
    console.log("  npx hardhat run scripts/check-transaction-events.ts \\");
    console.log("    0x1234567890abcdef...");
    console.log("");
    return;
  }

  const txHash = args[0];

  if (!txHash.startsWith("0x") || txHash.length !== 66) {
    console.error("❌ Invalid transaction hash. Must be 0x followed by 64 hex characters.");
    process.exitCode = 1;
    return;
  }

  await checkTransactionEvents(txHash);
}

// Export for potential use in other scripts
export { checkTransactionEvents };

// Run if called directly
const isMainModule = import.meta.url.endsWith(process.argv[1]);
if (isMainModule) {
  main().catch((error) => {
    console.error("❌ Script failed:", error);
    process.exitCode = 1;
  });
}
