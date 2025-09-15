import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { network } from "hardhat";
import { parseEther } from "viem";
import { GasReporter } from "./utils/gasReporter.js";
import { generateValidatorData, measureGas, generateVariableAmounts, calculateTotalValue } from "./utils/testHelpers.js";

describe("Gas Cost Comparison: New vs Legacy", async function () {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  // Mock deposit contract address (for testing)
  const mockDepositContract = "0x00000000219ab540356cBB839Cbe05303d7705Fa";

  // Initialize gas reporter
  const gasReporter = new GasReporter(20, 3000); // 20 gwei, $3000 ETH

  async function runGasComparison() {
    console.log("\n🔥 GAS COMPARISON ANALYSIS 🔥\n");

    // Deploy both contracts
    const newContract = await viem.deployContract("FigmentEth2Depositor", [mockDepositContract]);
    const legacyContract = await viem.deployContract("FigmentEth2Depositor0x01", [mockDepositContract]);

    console.log("Contracts deployed:");
    console.log(`  New Contract: ${newContract.address}`);
    console.log(`  Legacy Contract: ${legacyContract.address}\n`);

    const testCases = [
      { validators: 1, description: "Single Validator" },
      { validators: 5, description: "Small Batch (5 validators)" },
      { validators: 10, description: "Medium Batch (10 validators)" },
      { validators: 20, description: "Large Batch (20 validators)" },
    ];

    const results: Array<{
      case: string;
      validators: number;
      legacyGas: bigint;
      newGas: bigint;
      difference: bigint;
      percentChange: number;
    }> = [];

    for (const testCase of testCases) {
      console.log(`\n📊 Testing: ${testCase.description}`);
      console.log("─".repeat(50));

      const { pubkeys, withdrawalCredentials, signatures, depositDataRoots } =
        generateValidatorData(testCase.validators);

      // Legacy contract test (32 ETH per validator)
      const legacyValue = parseEther("32") * BigInt(testCase.validators);
      const legacyArgs = [pubkeys, withdrawalCredentials, signatures, depositDataRoots];

      const legacyGas = await measureGas(
        publicClient,
        legacyContract.address,
        legacyContract.abi,
        "deposit",
        legacyArgs,
        legacyValue
      );

      // New contract test (mixed amounts: 32 ETH + variable amounts)
      const amounts = generateVariableAmounts(testCase.validators);
      const newValue = calculateTotalValue(amounts);
      const newArgs = [pubkeys, withdrawalCredentials, signatures, depositDataRoots, amounts];

      const newGas = await measureGas(
        publicClient,
        newContract.address,
        newContract.abi,
        "deposit",
        newArgs,
        newValue
      );

      // Use gas reporter for formatted output
      const comparison = gasReporter.addComparison(
        testCase.description,
        legacyGas,
        newGas
      );

      gasReporter.printComparison(comparison);

      results.push({
        case: testCase.description,
        validators: testCase.validators,
        legacyGas,
        newGas,
        difference: comparison.difference,
        percentChange: comparison.percentChange,
      });
    }

    // Summary using gas reporter
    gasReporter.printSummary();

    return results;
  }

  it("Should compare gas costs across different scenarios", async function () {
    const results = await runGasComparison();

    // Basic assertion that we got results
    assert.ok(results.length > 0, "Should have gas comparison results");

    // Log that we can access individual results for further analysis
    console.log(`\n✅ Gas comparison completed with ${results.length} test cases`);
  });

  it("Should show deployment gas costs", async function () {
    console.log("\n🏗️  DEPLOYMENT GAS COMPARISON");
    console.log("═".repeat(50));

    // Get deployment gas estimates
    const newDeployment = await viem.deployContract("FigmentEth2Depositor", [mockDepositContract]);
    const legacyDeployment = await viem.deployContract("FigmentEth2Depositor0x01", [mockDepositContract]);

    // Get contract bytecode sizes
    const newBytecode = await publicClient.getCode({ address: newDeployment.address });
    const legacyBytecode = await publicClient.getCode({ address: legacyDeployment.address });

    console.log(`New Contract Bytecode:    ${newBytecode ? newBytecode.length : 0} chars`);
    console.log(`Legacy Contract Bytecode: ${legacyBytecode ? legacyBytecode.length : 0} chars`);

    const sizeDifference = (newBytecode?.length || 0) - (legacyBytecode?.length || 0);
    console.log(`Size Difference:          ${sizeDifference > 0 ? '+' : ''}${sizeDifference} chars`);

    assert.ok(newDeployment.address, "New contract should deploy");
    assert.ok(legacyDeployment.address, "Legacy contract should deploy");
  });
});
