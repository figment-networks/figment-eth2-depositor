// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {FigmentEth2DepositorPectra} from "./FigmentEth2DepositorPectra.sol";
import {Test} from "forge-std/src/Test.sol";

contract FigmentEth2DepositorPectraTest is Test {
  FigmentEth2DepositorPectra depositor;

  function setUp() public {
    // Mock deposit contract address for testing
    address mockDepositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
    depositor = new FigmentEth2DepositorPectra(mockDepositContract);
  }
}
