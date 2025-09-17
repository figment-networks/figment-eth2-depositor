import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { network } from "hardhat";

describe("FigmentEth2DepositorV0", async function () {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  it("Should deploy with correct deposit contract address", async function () {
    const mockDepositContract = "0x00000000219ab540356cBB839Cbe05303d7705Fa"; // Ethereum 2.0 deposit contract

    const depositor = await viem.deployContract("FigmentEth2DepositorV0", [mockDepositContract]);

    // Check that the contract was deployed
    assert.ok(depositor.address);

    // Check that the deposit contract address was set correctly
    const contractDepositContract = await publicClient.readContract({
      address: depositor.address,
      abi: depositor.abi,
      functionName: "depositContract",
      args: [],
    }) as string;

    assert.equal(contractDepositContract.toLowerCase(), mockDepositContract.toLowerCase());
  });

  it("Should be initially unpaused", async function () {
    const mockDepositContract = "0x00000000219ab540356cBB839Cbe05303d7705Fa";
    const depositor = await viem.deployContract("FigmentEth2DepositorV0", [mockDepositContract]);

    const paused = await publicClient.readContract({
      address: depositor.address,
      abi: depositor.abi,
      functionName: "paused",
      args: [],
    });

    assert.equal(paused, false);
  });
});
