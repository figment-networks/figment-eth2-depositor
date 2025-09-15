import { parseEther, parseGwei } from "viem";

export function generateValidatorData(count: number) {
  const pubkeys = Array(count).fill(0).map((_, i) =>
    ("0x" + i.toString(16).padStart(2, '0').repeat(48)) as `0x${string}`
  );
  const withdrawalCredentials = Array(count).fill(0).map((_, i) =>
    ("0x" + (i + 1).toString(16).padStart(2, '0').repeat(32)) as `0x${string}`
  );
  const signatures = Array(count).fill(0).map((_, i) =>
    ("0x" + (i + 2).toString(16).padStart(2, '0').repeat(96)) as `0x${string}`
  );
  const depositDataRoots = Array(count).fill(0).map((_, i) =>
    ("0x" + (i + 3).toString(16).padStart(2, '0').repeat(32)) as `0x${string}`
  );

  return { pubkeys, withdrawalCredentials, signatures, depositDataRoots };
}

export async function measureGas(
  publicClient: any,
  contractAddress: `0x${string}`,
  abi: any,
  functionName: string,
  args: any[],
  value: bigint
): Promise<bigint> {
  try {
    const gas = await publicClient.estimateContractGas({
      address: contractAddress,
      abi,
      functionName,
      args,
      value,
    });
    return gas;
  } catch (error: any) {
    // no fallback estimation
    throw error;
  }
}

export function generateVariableAmountsGwei(count: number): bigint[] {
  return Array(count).fill(0).map((_, i) => {
    if (i === 0) return parseGwei("32"); // First validator always 32 ETH in gwei
    return parseGwei((32 + i * 2).toString()); // Increasing amounts: 32, 34, 36, 38, etc. in gwei
  });
}

export function generateVariableAmounts(count: number): bigint[] {
  // For legacy contracts that expect wei amounts
  return Array(count).fill(0).map((_, i) => {
    if (i === 0) return parseEther("32"); // First validator always 32 ETH
    return parseEther((32 + i * 2).toString()); // Increasing amounts: 32, 34, 36, 38, etc.
  });
}

export function calculateTotalValue(amounts: bigint[]): bigint {
  return amounts.reduce((sum, amount) => sum + amount, 0n);
}

export function calculateTotalValueFromGwei(amountsGwei: bigint[]): bigint {
  // Convert gwei amounts to wei for total ETH value
  return amountsGwei.reduce((sum, amountGwei) => sum + (amountGwei * BigInt(1e9)), 0n);
}

// Utility to convert gwei array to display-friendly ETH amounts
export function gweiToEthStrings(amountsGwei: bigint[]): string[] {
  return amountsGwei.map(gwei => (Number(gwei) / 1e9).toString());
}
