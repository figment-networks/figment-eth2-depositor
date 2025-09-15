import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { network } from "hardhat";

describe("FigmentEth2Depositor", async function () {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  it("TODO", async function () {
    const counter = await viem.deployContract("FigmentEth2Depositor");

    await viem.assertions.emitWithArgs(
      counter.write.inc(),
      counter,
      "Increment",
      [1n],
    );
  });
});
