// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {FigmentEth2Depositor} from "./FigmentEth2Depositor.sol";
import {Test} from "forge-std/src/Test.sol";

contract FigmentEth2DepositorTest is Test {
  FigmentEth2Depositor depositor;

  function setUp() public {
    // Mock deposit contract address for testing
    address mockDepositContract = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
    depositor = new FigmentEth2Depositor(mockDepositContract);
  }
}
