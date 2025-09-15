import { network } from "hardhat";
import { parseGwei, encodeFunctionData, parseAbiItem, decodeEventLog } from "viem";
import { generateValidatorData } from "../test/utils/testHelpers.js";

// Event signatures
const DEPOSIT_EVENT_ABI = parseAbiItem("event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index)");
const FIGMENT_DEPOSIT_EVENT_ABI = parseAbiItem("event DepositEvent(address from, uint256 nodesAmount, uint256 totalAmount)");

async function analyzeTransactionReceipt(receipt: any) {
  console.log("🔍 Analyzing Transaction Events");
  console.log("═".repeat(60));
  console.log(`Transaction Hash: ${receipt.transactionHash}`);
  console.log(`Block Number: ${receipt.blockNumber}`);
  console.log(`Gas Used: ${receipt.gasUsed.toLocaleString()}`);
  console.log("");

  // Filter logs for DepositEvent from deposit contract
  const depositEvents = receipt.logs.filter((log: any) => {
    try {
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

  console.log(`📊 Found ${depositEvents.length} deposit contract events`);
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
      console.log(`Pubkey:     ${(decoded.args.pubkey as string).slice(0, 20)}...${(decoded.args.pubkey as string).slice(-20)}`);
      console.log(`Withdrawal: ${decoded.args.withdrawal_credentials}`);
      console.log(`Signature:  ${(decoded.args.signature as string).slice(0, 20)}...${(decoded.args.signature as string).slice(-20)}`);
      console.log("─".repeat(40));
      console.log("");

    } catch (error) {
      console.error(`❌ Error parsing deposit event #${i + 1}:`, error);
    }
  }

  // Also check for Figment contract events
  const figmentEvents = receipt.logs.filter((log: any) => {
    try {
      decodeEventLog({
        abi: [FIGMENT_DEPOSIT_EVENT_ABI],
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

    figmentEvents.forEach((log: any, i: number) => {
      try {
        const decoded = decodeEventLog({
          abi: [FIGMENT_DEPOSIT_EVENT_ABI],
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
}

async function demoEventMonitoring() {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();
  const [walletClient] = await viem.getWalletClients();

  console.log("🎬 Demo: Deposit Event Monitoring");
  console.log("═".repeat(60));
  console.log("");

  // Deploy mock deposit contract
  console.log("📦 Deploying mock deposit contract...");
  const mockDepositContract = await viem.deployContract("MockDepositContract", []);
  console.log(`✅ Mock Deposit Contract: ${mockDepositContract.address}`);

  // Deploy Figment contract
  console.log("📦 Deploying Figment contract...");
  const figmentContract = await viem.deployContract("FigmentEth2Depositor", [mockDepositContract.address]);
  console.log(`✅ Figment Contract: ${figmentContract.address}`);
  console.log("");

  // Generate test validator data
  console.log("🧪 Generating test validator data...");
  const validatorData = generateValidatorData(3); // 3 validators
  const amountsGwei = [
    parseGwei("32"), // 32 ETH
    parseGwei("35"), // 35 ETH
    parseGwei("40"), // 40 ETH
  ];

  const totalValue = amountsGwei.reduce((sum, gwei) => sum + (gwei * BigInt(1e9)), 0n);
  console.log(`Total ETH to deposit: ${Number(totalValue) / 1e18} ETH`);
  console.log("");

  // Make the deposit transaction
  console.log("💰 Making deposit transaction...");
  try {
    const txHash = await walletClient.sendTransaction({
      to: figmentContract.address,
      value: totalValue,
      data: encodeFunctionData({
        abi: figmentContract.abi,
        functionName: "deposit",
        args: [
          validatorData.pubkeys,
          validatorData.withdrawalCredentials,
          validatorData.signatures,
          validatorData.depositDataRoots,
          amountsGwei
        ]
      })
    });

    console.log(`✅ Transaction submitted: ${txHash}`);
    console.log("⏳ Waiting for confirmation...");

    // Wait for transaction to be mined
    const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
    console.log(`✅ Transaction mined in block ${receipt.blockNumber}`);
    console.log(`Gas used: ${receipt.gasUsed.toLocaleString()}`);
    console.log("");

    // Check the events in the transaction
    console.log("🔍 Analyzing transaction events...");
    console.log("");

    // Analyze the receipt directly instead of fetching it again
    await analyzeTransactionReceipt(receipt);

  } catch (error) {
    console.error("❌ Transaction failed:", error);
    throw error;
  }

  console.log("🎉 Demo completed successfully!");
}

async function main() {
  try {
    await demoEventMonitoring();
  } catch (error) {
    console.error("❌ Demo failed:", error);
    process.exitCode = 1;
  }
}

// Run the demo
main();
