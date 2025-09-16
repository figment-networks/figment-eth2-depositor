import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { network } from "hardhat";

describe("FigmentEth2Depositor", async function () {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();
  const mockDepositContract = "0x00000000219ab540356cBB839Cbe05303d7705Fa";

  const deployDepositor = async () => {
    return viem.deployContract("FigmentEth2Depositor", [mockDepositContract]);
  }

  it("Should deploy with correct deposit contract address", async function () {
    const depositor = await deployDepositor();

    // Check that the contract was deployed
    assert.ok(depositor.address);

    // Check that the deposit contract address was set correctly
    const contractDepositContract = await publicClient.readContract({
      address: depositor.address,
      abi: depositor.abi,
      functionName: "depositContract",
      args: [],
    });

    assert.equal((contractDepositContract as string).toLowerCase(), mockDepositContract.toLowerCase());
  });

  it("Should be initially unpaused", async function () {
    const depositor = await deployDepositor();

    const paused = await publicClient.readContract({
      address: depositor.address,
      abi: depositor.abi,
      functionName: "paused",
      args: [],
    });

    assert.equal(paused, false);
  });
});
