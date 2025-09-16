import { network } from "hardhat";
import { parseEther, parseGwei } from "viem";
import { GasReporter } from "../test/utils/gasReporter.js";
import { generateValidatorData, measureGas, generateVariableAmountsGwei, calculateTotalValueFromGwei, gweiToEthStrings } from "../test/utils/testHelpers.js";

async function main() {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  console.log("🔥 Gas Analysis Tool 🔥\n");

  // Initialize gas reporter
  const gasReporter = new GasReporter(20, 3000); // 20 gwei, $3000 ETH

  // Deploy mock deposit contract first
  console.log("Deploying mock deposit contract...");
  const mockContract = await viem.deployContract("MockDepositContract", []);
  const mockDepositContract = mockContract.address;
  console.log(`✅ Mock Deposit Contract deployed at: ${mockDepositContract}\n`);

  // Deploy contracts
  console.log("Deploying test contracts...");
  const newContract = await viem.deployContract("FigmentEth2DepositorPectra", [mockDepositContract]);
  const legacyContract = await viem.deployContract("FigmentEth2Depositor0x01", [mockDepositContract]);

  console.log(`✅ New Contract deployed at: ${newContract.address}`);
  console.log(`✅ Legacy Contract deployed at: ${legacyContract.address}\n`);


  // Test single validator
  const singleValidatorData = generateValidatorData(1);

  // Legacy: 32 ETH
  const legacyGas = await measureGas(
    publicClient,
    legacyContract.address,
    legacyContract.abi,
    "deposit",
    [
      singleValidatorData.pubkeys,
      singleValidatorData.withdrawalCredentials,
      singleValidatorData.signatures,
      singleValidatorData.depositDataRoots
    ],
    parseEther("32")
  );

  // New: Custom amount (35 ETH in gwei)
  const amountGwei = parseGwei("35");
  const newGas = await measureGas(
    publicClient,
    newContract.address,
    newContract.abi,
    "deposit",
    [
      singleValidatorData.pubkeys,
      singleValidatorData.withdrawalCredentials,
      singleValidatorData.signatures,
      singleValidatorData.depositDataRoots,
      [amountGwei]
    ],
    parseEther("35") // Still need to send actual ETH value in wei
  );

  const singleComparison = gasReporter.addComparison("Single Validator", legacyGas, newGas);
  gasReporter.printComparison(singleComparison);

  // Test multiple validators
  const multiValidatorData = generateValidatorData(5);

  // Legacy: 5 × 32 ETH = 160 ETH
  const legacyMultiGas = await measureGas(
    publicClient,
    legacyContract.address,
    legacyContract.abi,
    "deposit",
    [
      multiValidatorData.pubkeys,
      multiValidatorData.withdrawalCredentials,
      multiValidatorData.signatures,
      multiValidatorData.depositDataRoots
    ],
    parseEther("160")
  );

  // New: Variable amounts in gwei using helper
  const amountsGwei = generateVariableAmountsGwei(5);
  const totalValue = calculateTotalValueFromGwei(amountsGwei);

  console.log(`  Using gwei amounts: [${gweiToEthStrings(amountsGwei).join(', ')}] ETH`);

  const newMultiGas = await measureGas(
    publicClient,
    newContract.address,
    newContract.abi,
    "deposit",
    [
      multiValidatorData.pubkeys,
      multiValidatorData.withdrawalCredentials,
      multiValidatorData.signatures,
      multiValidatorData.depositDataRoots,
      amountsGwei
    ],
    totalValue
  );

  const multiComparison = gasReporter.addComparison("Multiple Validators (5)", legacyMultiGas, newMultiGas);
  gasReporter.printComparison(multiComparison);

  // Print summary
  gasReporter.printSummary();

  console.log("\n✅ Gas analysis complete!");
  console.log("\n💡 To run comprehensive tests:");
  console.log("   npx hardhat test test/GasComparison.ts");
  console.log("\n💡 To run all tests:");
  console.log("   npx hardhat test");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
