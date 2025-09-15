import { parseEther, formatGwei, formatEther } from "viem";

export interface GasResult {
  functionName: string;
  gasUsed: bigint;
  gasCost: bigint; // in wei
  gasCostUSD: number;
}

export interface GasComparisonResult {
  testName: string;
  legacy: GasResult;
  new: GasResult;
  difference: bigint;
  percentChange: number;
  savings: boolean;
}

export class GasReporter {
  private gasPrice: bigint;
  private ethPriceUSD: number;
  private results: GasComparisonResult[] = [];

  constructor(gasPriceGwei: number = 20, ethPriceUSD: number = 3000) {
    this.gasPrice = parseEther(gasPriceGwei.toString()) / parseEther("1000000000"); // Convert gwei to wei
    this.ethPriceUSD = ethPriceUSD;
  }

  calculateGasCost(gasUsed: bigint): { costWei: bigint; costUSD: number } {
    const costWei = gasUsed * this.gasPrice;
    const costUSD = Number(formatEther(costWei)) * this.ethPriceUSD;
    return { costWei, costUSD };
  }

  createGasResult(functionName: string, gasUsed: bigint): GasResult {
    const { costWei, costUSD } = this.calculateGasCost(gasUsed);
    return {
      functionName,
      gasUsed,
      gasCost: costWei,
      gasCostUSD: costUSD,
    };
  }

  addComparison(
    testName: string,
    legacyGas: bigint,
    newGas: bigint,
    functionName: string = "deposit"
  ): GasComparisonResult {
    const legacy = this.createGasResult(functionName, legacyGas);
    const newResult = this.createGasResult(functionName, newGas);
    const difference = newGas - legacyGas;
    const percentChange = Number((difference * 100n) / legacyGas);
    const savings = difference < 0;

    const comparison: GasComparisonResult = {
      testName,
      legacy,
      new: newResult,
      difference,
      percentChange,
      savings,
    };

    this.results.push(comparison);
    return comparison;
  }

  printComparison(comparison: GasComparisonResult) {
    console.log(`\n📊 ${comparison.testName}`);
    console.log("─".repeat(50));
    console.log(`Legacy Gas:     ${comparison.legacy.gasUsed.toLocaleString()} gas`);
    console.log(`New Gas:        ${comparison.new.gasUsed.toLocaleString()} gas`);
    console.log(`Difference:     ${comparison.difference > 0 ? '+' : ''}${comparison.difference.toLocaleString()} gas`);
    console.log(`% Change:       ${comparison.percentChange > 0 ? '+' : ''}${comparison.percentChange.toFixed(2)}%`);

    if (comparison.savings) {
      console.log(`💚 Gas Savings: ${(-comparison.difference).toLocaleString()} gas`);
      console.log(`💰 Cost Savings: $${(-comparison.new.gasCostUSD + comparison.legacy.gasCostUSD).toFixed(6)}`);
    } else {
      console.log(`🔴 Gas Increase: ${comparison.difference.toLocaleString()} gas`);
      console.log(`💸 Cost Increase: $${(comparison.new.gasCostUSD - comparison.legacy.gasCostUSD).toFixed(6)}`);
    }
  }

  printSummary() {
    if (this.results.length === 0) {
      console.log("\n❌ No gas comparison results to summarize");
      return;
    }

    console.log("\n" + "═".repeat(70));
    console.log("📈 GAS COMPARISON SUMMARY");
    console.log("═".repeat(70));

    const totalLegacyGas = this.results.reduce((sum, r) => sum + r.legacy.gasUsed, 0n);
    const totalNewGas = this.results.reduce((sum, r) => sum + r.new.gasUsed, 0n);
    const totalDifference = totalNewGas - totalLegacyGas;
    const overallPercent = Number((totalDifference * 100n) / totalLegacyGas);

    console.log(`Total Legacy Gas:   ${totalLegacyGas.toLocaleString()}`);
    console.log(`Total New Gas:      ${totalNewGas.toLocaleString()}`);
    console.log(`Overall Difference: ${totalDifference > 0 ? '+' : ''}${totalDifference.toLocaleString()} (${overallPercent > 0 ? '+' : ''}${overallPercent.toFixed(2)}%)`);

    const { costUSD: totalLegacyCost } = this.calculateGasCost(totalLegacyGas);
    const { costUSD: totalNewCost } = this.calculateGasCost(totalNewGas);
    const totalCostDiff = totalNewCost - totalLegacyCost;

    console.log(`\n💰 Cost Analysis (${Number(this.gasPrice) / 1e9} gwei, $${this.ethPriceUSD} ETH):`);
    console.log(`Total Legacy Cost:  $${totalLegacyCost.toFixed(6)}`);
    console.log(`Total New Cost:     $${totalNewCost.toFixed(6)}`);
    console.log(`Total Cost Diff:    ${totalCostDiff > 0 ? '+' : ''}$${totalCostDiff.toFixed(6)}`);

    if (totalDifference < 0) {
      console.log(`\n🎉 Overall gas savings: ${(-totalDifference).toLocaleString()} gas!`);
      console.log(`🎉 Overall cost savings: $${(-totalCostDiff).toFixed(6)}!`);
    } else {
      console.log(`\n⚠️  Overall gas increase: ${totalDifference.toLocaleString()} gas`);
      console.log(`⚠️  Overall cost increase: $${totalCostDiff.toFixed(6)}`);
    }

    // Individual test breakdown
    console.log(`\n📋 Individual Test Results:`);
    this.results.forEach((result, index) => {
      const icon = result.savings ? "💚" : "🔴";
      const change = result.savings ? "savings" : "increase";
      console.log(`  ${index + 1}. ${icon} ${result.testName}: ${Math.abs(result.percentChange).toFixed(2)}% ${change}`);
    });

    console.log("═".repeat(70));
  }

  getResults(): GasComparisonResult[] {
    return this.results;
  }

  reset() {
    this.results = [];
  }
}
