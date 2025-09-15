// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {FigmentEth2Depositor} from "./FigmentEth2Depositor.sol";
import {Test} from "forge-std/Test.sol";

contract FigmentEth2DepositorTest is Test {
  FigmentEth2Depositor depositor;

  function setUp() public {
    depositor = new FigmentEth2Depositor();
  }
}
