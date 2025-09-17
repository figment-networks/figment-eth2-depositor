// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {FigmentEth2DepositorV1} from "./FigmentEth2DepositorV1.sol";
import {Test} from "forge-std/src/Test.sol";
import {MockDepositContract} from "./MockDepositContract.sol";
import {IDepositContract} from "./interfaces/IDepositContract.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract FigmentEth2DepositorV1Test is Test {
    FigmentEth2DepositorV1 figmentDepositor;
    MockDepositContract mockDepositContract;

    function setUp() public {
        // Deploy mock deposit contract for testing
        mockDepositContract = new MockDepositContract();
        figmentDepositor = new FigmentEth2DepositorV1(address(mockDepositContract));
    }

    // ============ Constructor Tests ============

    function test_Constructor_Success() public {
        address ethDepositContract = address(0x123);
        FigmentEth2DepositorV1 newFigmentEth2DepositorV1 = new FigmentEth2DepositorV1(ethDepositContract);

        assertEq(address(newFigmentEth2DepositorV1.depositContract()), ethDepositContract);
        assertEq(newFigmentEth2DepositorV1.owner(), address(this));
    }

    function test_Constructor_ZeroAddress_Reverts() public {
        vm.expectRevert(FigmentEth2DepositorV1.ZeroAddress.selector);
        new FigmentEth2DepositorV1(address(0));
    }

    // ============ Receive Function Tests ============

    function test_Receive_DirectEthTransfer_Reverts() public {
        // Capture pre-transaction balances
        uint256 preSenderBalance = address(this).balance;
        uint256 preContractBalance = address(figmentDepositor).balance;
        uint256 preMockBalance = address(mockDepositContract).balance;

        vm.expectRevert(FigmentEth2DepositorV1.DirectEthTransferNotAllowed.selector);
        address(figmentDepositor).call{value: 1 ether}("");

        // Capture post-transaction balances
        uint256 postSenderBalance = address(this).balance;
        uint256 postContractBalance = address(figmentDepositor).balance;
        uint256 postMockBalance = address(mockDepositContract).balance;

        // Verify balances after revert
        assertEq(postSenderBalance, preSenderBalance, "Sender balance should be unchanged after revert");
        assertEq(postContractBalance, preContractBalance, "Contract balance should remain zero after revert");
        assertEq(postMockBalance, preMockBalance, "Mock contract balance should be unchanged after revert");
        assertEq(postContractBalance, 0, "Contract balance should be zero");
    }

    function test_Receive_DirectEthTransfer_WithData_Reverts() public {
        // Capture pre-transaction balances
        uint256 preSenderBalance = address(this).balance;
        uint256 preContractBalance = address(figmentDepositor).balance;
        uint256 preMockBalance = address(mockDepositContract).balance;

        vm.expectRevert();
        Address.functionCallWithValue(address(figmentDepositor), hex"1234", 1 ether);
        // Capture post-transaction balances
        uint256 postSenderBalance = address(this).balance;
        uint256 postContractBalance = address(figmentDepositor).balance;
        uint256 postMockBalance = address(mockDepositContract).balance;

        // Verify balances after revert
        assertEq(postSenderBalance, preSenderBalance, "Sender balance should be unchanged after revert");
        assertEq(postContractBalance, preContractBalance, "Contract balance should remain zero after revert");
        assertEq(postMockBalance, preMockBalance, "Mock contract balance should be unchanged after revert");
        assertEq(postContractBalance, 0, "Contract balance should be zero");
    }

    // ============ Helper Functions ============

    function _createValidValidatorData(uint256 amountGwei)
        internal
        pure
        returns (
            bytes memory pubkey,
            bytes memory withdrawalCredentials,
            bytes memory signature,
            bytes32 depositDataRoot
        )
    {
        // Create valid-length data
        pubkey = new bytes(48);
        withdrawalCredentials = new bytes(32);
        signature = new bytes(96);
        depositDataRoot = keccak256(abi.encodePacked(amountGwei));

        // Fill with some data (not cryptographically valid, but length is correct)
        for (uint256 i = 0; i < 48; i++) {
            pubkey[i] = bytes1(uint8(i % 256));
        }
        for (uint256 i = 0; i < 32; i++) {
            withdrawalCredentials[i] = bytes1(uint8(i % 256));
        }
        for (uint256 i = 0; i < 96; i++) {
            signature[i] = bytes1(uint8(i % 256));
        }
    }

    function _createValidValidatorDataWithoutPubkey(uint256 amountGwei)
        internal
        pure
        returns (bytes memory withdrawalCredentials, bytes memory signature, bytes32 depositDataRoot)
    {
        // Create valid-length data
        withdrawalCredentials = new bytes(32);
        signature = new bytes(96);
        depositDataRoot = keccak256(abi.encodePacked(amountGwei));

        // Fill with some data (not cryptographically valid, but length is correct)
        for (uint256 i = 0; i < 32; i++) {
            withdrawalCredentials[i] = bytes1(uint8(i % 256));
        }
        for (uint256 i = 0; i < 96; i++) {
            signature[i] = bytes1(uint8(i % 256));
        }
    }

    // ============ Deposit Parameter Validation Tests ============

    function test_Deposit_EmptyPubkeysArray_Reverts() public {
        bytes[] memory pubkeys = new bytes[](0);
        bytes[] memory withdrawalCredentials = new bytes[](0);
        bytes[] memory signatures = new bytes[](0);
        bytes32[] memory depositDataRoots = new bytes32[](0);
        uint256[] memory amountsGwei = new uint256[](0);

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.ParametersMismatch.selector, 0, 500));
        figmentDepositor.deposit{value: 0}(pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei);
    }

    function test_Deposit_TooManyNodes_Reverts() public {
        uint256 tooManyNodes = 501; // Exceeds NODES_MAX_AMOUNT
        bytes[] memory pubkeys = new bytes[](tooManyNodes);
        bytes[] memory withdrawalCredentials = new bytes[](tooManyNodes);
        bytes[] memory signatures = new bytes[](tooManyNodes);
        bytes32[] memory depositDataRoots = new bytes32[](tooManyNodes);
        uint256[] memory amountsGwei = new uint256[](tooManyNodes);

        // Fill arrays with valid data
        for (uint256 i = 0; i < tooManyNodes; i++) {
            (pubkeys[i], withdrawalCredentials[i], signatures[i], depositDataRoots[i]) =
                _createValidValidatorData(32_000_000_000); // 32 ETH in gwei
            amountsGwei[i] = 32_000_000_000;
        }

        uint256 totalValue = 32_000_000_000 * 1_000_000_000 * tooManyNodes; // Convert to wei

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.ParametersMismatch.selector, tooManyNodes, 500));
        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_PubkeysLengthMismatch_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](2); // Different length
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.ParametersMismatch.selector, 1, 0));
        figmentDepositor.deposit{value: 32 ether}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_SignaturesLengthMismatch_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](2); // Different length
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.ParametersMismatch.selector, 1, 0));
        figmentDepositor.deposit{value: 32 ether}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_DepositDataRootsLengthMismatch_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](2); // Different length
        uint256[] memory amountsGwei = new uint256[](1);

        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.ParametersMismatch.selector, 1, 0));
        figmentDepositor.deposit{value: 32 ether}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_AmountsGweiLengthMismatch_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](2); // Different length

        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.ParametersMismatch.selector, 1, 0));
        figmentDepositor.deposit{value: 32 ether}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    // ============ Deposit Amount Validation Tests ============

    function test_Deposit_AmountBelowMinimum_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 belowMinimum = 31_999_999_999; // Just below 32 ETH in gwei
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(belowMinimum);
        amountsGwei[0] = belowMinimum;

        vm.expectRevert(
            abi.encodeWithSelector(FigmentEth2DepositorV1.InsufficientAmount.selector, belowMinimum, 32_000_000_000)
        );
        figmentDepositor.deposit{value: belowMinimum * 1_000_000_000}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_AmountAboveMaximum_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 aboveMaximum = 2_048_000_000_001; // Just above 2048 ETH in gwei
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(aboveMaximum);
        amountsGwei[0] = aboveMaximum;

        vm.expectRevert(
            abi.encodeWithSelector(FigmentEth2DepositorV1.InsufficientAmount.selector, aboveMaximum, 2_048_000_000_000)
        );
        figmentDepositor.deposit{value: aboveMaximum * 1_000_000_000}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_EthAmountMismatch_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 amountGwei = 32_000_000_000; // 32 ETH in gwei
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(amountGwei);
        amountsGwei[0] = amountGwei;

        uint256 expectedValue = amountGwei * 1_000_000_000; // Convert to wei
        uint256 wrongValue = expectedValue + 1; // Send 1 wei too much

        vm.expectRevert(
            abi.encodeWithSelector(FigmentEth2DepositorV1.EthAmountMismatch.selector, wrongValue, expectedValue)
        );
        figmentDepositor.deposit{value: wrongValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_EthAmountTooLittle_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 amountGwei = 32_000_000_000; // 32 ETH in gwei
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(amountGwei);
        amountsGwei[0] = amountGwei;

        uint256 expectedValue = amountGwei * 1_000_000_000; // Convert to wei
        uint256 wrongValue = expectedValue - 1; // Send 1 wei too little

        // Capture pre-transaction balances
        uint256 preSenderBalance = address(this).balance;
        uint256 preContractBalance = address(figmentDepositor).balance;
        uint256 preMockBalance = address(mockDepositContract).balance;

        vm.expectRevert(
            abi.encodeWithSelector(FigmentEth2DepositorV1.EthAmountMismatch.selector, wrongValue, expectedValue)
        );
        figmentDepositor.deposit{value: wrongValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        // Capture post-transaction balances
        uint256 postSenderBalance = address(this).balance;
        uint256 postContractBalance = address(figmentDepositor).balance;
        uint256 postMockBalance = address(mockDepositContract).balance;

        // Verify balances after revert
        assertEq(postSenderBalance, preSenderBalance, "Sender balance should be unchanged after revert");
        assertEq(postContractBalance, preContractBalance, "Contract balance should remain zero after revert");
        assertEq(postMockBalance, preMockBalance, "Mock contract balance should be unchanged after revert");
        assertEq(postContractBalance, 0, "Contract balance should be zero");
    }

    function test_Deposit_MultipleValidatorsAmountValidation() public {
        bytes[] memory pubkeys = new bytes[](2);
        bytes[] memory withdrawalCredentials = new bytes[](2);
        bytes[] memory signatures = new bytes[](2);
        bytes32[] memory depositDataRoots = new bytes32[](2);
        uint256[] memory amountsGwei = new uint256[](2);

        // First validator with valid amount
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        // Second validator with invalid amount (too low)
        uint256 invalidAmount = 31_999_999_999;
        (pubkeys[1], withdrawalCredentials[1], signatures[1], depositDataRoots[1]) =
            _createValidValidatorData(invalidAmount);
        amountsGwei[1] = invalidAmount;

        uint256 totalValue = (32_000_000_000 + invalidAmount) * 1_000_000_000;

        vm.expectRevert(
            abi.encodeWithSelector(FigmentEth2DepositorV1.InsufficientAmount.selector, invalidAmount, 32_000_000_000)
        );
        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    // ============ Deposit Data Validation Tests ============

    function test_Deposit_InvalidPubkeyLength_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        // Create pubkey with wrong length (47 bytes instead of 48)
        pubkeys[0] = new bytes(47);
        for (uint256 i = 0; i < 47; i++) {
            pubkeys[0][i] = bytes1(uint8(i % 256));
        }

        (withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorDataWithoutPubkey(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.InvalidValidatorData.selector, 0, "pubkey"));
        figmentDepositor.deposit{value: 32 ether}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_InvalidWithdrawalCredentialsLength_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        // Create withdrawal credentials with wrong length (31 bytes instead of 32)
        bytes[] memory wrongWithdrawalCredentials = new bytes[](1);
        wrongWithdrawalCredentials[0] = new bytes(31);
        for (uint256 i = 0; i < 31; i++) {
            wrongWithdrawalCredentials[0][i] = bytes1(uint8(i % 256));
        }

        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        vm.expectRevert(
            abi.encodeWithSelector(FigmentEth2DepositorV1.InvalidValidatorData.selector, 0, "withdrawal_credentials")
        );
        figmentDepositor.deposit{value: 32 ether}(
            pubkeys, wrongWithdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_InvalidSignatureLength_Reverts() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        // Create signature with wrong length (95 bytes instead of 96)
        bytes[] memory wrongSignatures = new bytes[](1);
        wrongSignatures[0] = new bytes(95);
        for (uint256 i = 0; i < 95; i++) {
            wrongSignatures[0][i] = bytes1(uint8(i % 256));
        }

        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.InvalidValidatorData.selector, 0, "signature"));
        figmentDepositor.deposit{value: 32 ether}(
            pubkeys, withdrawalCredentials, wrongSignatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_MultipleValidatorsDataValidation() public {
        bytes[] memory pubkeys = new bytes[](2);
        bytes[] memory withdrawalCredentials = new bytes[](2);
        bytes[] memory signatures = new bytes[](2);
        bytes32[] memory depositDataRoots = new bytes32[](2);
        uint256[] memory amountsGwei = new uint256[](2);

        // First validator with valid data
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        // Second validator with invalid pubkey length
        pubkeys[1] = new bytes(47); // Wrong length
        for (uint256 i = 0; i < 47; i++) {
            pubkeys[1][i] = bytes1(uint8(i % 256));
        }
        (withdrawalCredentials[1], signatures[1], depositDataRoots[1]) =
            _createValidValidatorDataWithoutPubkey(32_000_000_000);
        amountsGwei[1] = 32_000_000_000;

        uint256 totalValue = 64 ether;

        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.InvalidValidatorData.selector, 1, "pubkey"));
        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    // ============ Deposits are all or nothing Tests ============

    function test_Deposit_OneFailedDeposit_RevertsAll() public {
        bytes[] memory pubkeys = new bytes[](2);
        bytes[] memory withdrawalCredentials = new bytes[](2);
        bytes[] memory signatures = new bytes[](2);
        bytes32[] memory depositDataRoots = new bytes32[](2);
        uint256[] memory amountsGwei = new uint256[](2);

        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 33_000_000_000;

        (pubkeys[1], withdrawalCredentials[1], signatures[1], depositDataRoots[1]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[1] = 100_000_000_000;

        uint256 totalValue = 33_000_000_000 * 1_000_000_000 + 100_000_000_000 * 1_000_000_000;

        //This is the trapdoor to revert in the underlying Mock Deposit contract
        withdrawalCredentials[1] = hex"0000000000000000000000000000000000000000000000000000000000000000";

        // Capture pre-transaction balances
        uint256 preSenderBalance = address(this).balance;
        uint256 preContractBalance = address(figmentDepositor).balance;
        uint256 preMockBalance = address(mockDepositContract).balance;

        vm.expectRevert("bad withdrawal credentials");
        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        // Capture post-transaction balances
        uint256 postSenderBalance = address(this).balance;
        uint256 postContractBalance = address(figmentDepositor).balance;
        uint256 postMockBalance = address(mockDepositContract).balance;

        // Verify balances after revert
        assertEq(postSenderBalance, preSenderBalance, "Sender balance should be unchanged after revert");
        assertEq(postContractBalance, preContractBalance, "Contract balance should remain zero after revert");
        assertEq(postMockBalance, preMockBalance, "Mock contract balance should be unchanged after revert");
        assertEq(postContractBalance, 0, "Contract balance should be zero");
    }

    // ============ Successful Deposit Flow Tests ============

    function test_DepositFunction_WorksWithOneValidator() public {
        // This test ensures the deposit function still works even with the fallback function
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 amountGwei = 32_000_000_000;
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(amountGwei);
        amountsGwei[0] = amountGwei;

        uint256 totalValue = amountGwei * 1_000_000_000;

        // Expect the MockDepositContract event FIRST (it's emitted first during deposit)
        vm.expectEmit(true, true, true, true);
        emit IDepositContract.DepositEvent( // Template
            pubkeys[0],
            withdrawalCredentials[0],
            abi.encodePacked(uint64(amountGwei)),
            signatures[0],
            abi.encodePacked(uint64(1))
        );

        // Expect the FigmentEth2DepositorV1 event SECOND (it's emitted after the deposit)
        vm.expectEmit(true, true, true, true);
        emit FigmentEth2DepositorV1.DepositEvent(address(this), 1, totalValue);

        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        assertEq(mockDepositContract.depositCount(), 1);
    }

    function test_SuccessfulDeposit_BalanceVerification() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 amountGwei = 32_000_000_000;
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(amountGwei);
        amountsGwei[0] = amountGwei;

        uint256 totalValue = amountGwei * 1_000_000_000;

        // Capture pre-transaction balances
        uint256 preSenderBalance = address(this).balance;
        uint256 preContractBalance = address(figmentDepositor).balance;
        uint256 preMockBalance = address(mockDepositContract).balance;

        // Execute successful deposit
        vm.expectEmit(true, true, true, true);
        emit FigmentEth2DepositorV1.DepositEvent(address(this), 1, totalValue);

        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        // Capture post-transaction balances
        uint256 postSenderBalance = address(this).balance;
        uint256 postContractBalance = address(figmentDepositor).balance;
        uint256 postMockBalance = address(mockDepositContract).balance;

        // Verify balances after successful deposit
        assertEq(postSenderBalance, preSenderBalance - totalValue, "Sender balance should decrease by deposit amount");
        assertEq(postContractBalance, preContractBalance, "Contract balance should remain zero");
        assertEq(
            postMockBalance, preMockBalance + totalValue, "Mock contract balance should increase by deposit amount"
        );
        assertEq(postContractBalance, 0, "Contract balance should be zero");
        assertEq(mockDepositContract.depositCount(), 1, "Mock contract should record 1 deposit");
    }

    function test_Deposit_MultipleValidators_Success() public {
        uint256 validatorCount = 3;
        bytes[] memory pubkeys = new bytes[](validatorCount);
        bytes[] memory withdrawalCredentials = new bytes[](validatorCount);
        bytes[] memory signatures = new bytes[](validatorCount);
        bytes32[] memory depositDataRoots = new bytes32[](validatorCount);
        uint256[] memory amountsGwei = new uint256[](validatorCount);

        uint256 totalValue = 0;
        for (uint256 i = 0; i < validatorCount; i++) {
            uint256 amountGwei = 50_000_000_000 + (i * 1_000_000_000); // Different amounts
            (pubkeys[i], withdrawalCredentials[i], signatures[i], depositDataRoots[i]) =
                _createValidValidatorData(amountGwei);
            amountsGwei[i] = amountGwei;
            totalValue += amountGwei * 1_000_000_000;
        }

        // Expect the MockDepositContract event FIRST (it's emitted first during deposit)
        vm.expectEmit(true, true, true, true);
        emit IDepositContract.DepositEvent( // Template
            pubkeys[0],
            withdrawalCredentials[0],
            abi.encodePacked(uint64(50_000_000_000)),
            signatures[0],
            abi.encodePacked(uint64(1))
        );

        vm.expectEmit(true, true, true, true);
        emit IDepositContract.DepositEvent( // Template
            pubkeys[1],
            withdrawalCredentials[1],
            abi.encodePacked(uint64(51_000_000_000)),
            signatures[1],
            abi.encodePacked(uint64(2))
        );

        vm.expectEmit(true, true, true, true);
        emit IDepositContract.DepositEvent( // Template
            pubkeys[2],
            withdrawalCredentials[2],
            abi.encodePacked(uint64(52_000_000_000)),
            signatures[2],
            abi.encodePacked(uint64(3))
        );

        vm.expectEmit(true, true, true, true);
        emit FigmentEth2DepositorV1.DepositEvent(address(this), validatorCount, totalValue);

        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        // Verify mock deposit contract was called correctly
        assertEq(mockDepositContract.depositCount(), validatorCount);
    }

    function test_Deposit_MaximumValidators_Success() public {
        uint256 validatorCount = 500; // Maximum allowed
        bytes[] memory pubkeys = new bytes[](validatorCount);
        bytes[] memory withdrawalCredentials = new bytes[](validatorCount);
        bytes[] memory signatures = new bytes[](validatorCount);
        bytes32[] memory depositDataRoots = new bytes32[](validatorCount);
        uint256[] memory amountsGwei = new uint256[](validatorCount);

        uint256 amountGwei = 2_048_000_000_000; // 2048 ETH in gwei
        uint256 totalValue = amountGwei * 1_000_000_000 * validatorCount;

        for (uint256 i = 0; i < validatorCount; i++) {
            (pubkeys[i], withdrawalCredentials[i], signatures[i], depositDataRoots[i]) =
                _createValidValidatorData(amountGwei);
            amountsGwei[i] = amountGwei;
        }

        // Expect DepositEvent to be emitted
        vm.expectEmit(true, true, true, true);
        emit FigmentEth2DepositorV1.DepositEvent(address(this), validatorCount, totalValue);

        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        // Verify mock deposit contract was called correctly
        assertEq(mockDepositContract.depositCount(), validatorCount);
    }

    function test_Deposit_BoundaryAmounts_Success() public {
        bytes[] memory pubkeys = new bytes[](2);
        bytes[] memory withdrawalCredentials = new bytes[](2);
        bytes[] memory signatures = new bytes[](2);
        bytes32[] memory depositDataRoots = new bytes32[](2);
        uint256[] memory amountsGwei = new uint256[](2);

        // Minimum amount
        uint256 minAmount = 32_000_000_000; // 32 ETH in gwei
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(minAmount);
        amountsGwei[0] = minAmount;

        // Maximum amount
        uint256 maxAmount = 2_048_000_000_000; // 2048 ETH in gwei
        (pubkeys[1], withdrawalCredentials[1], signatures[1], depositDataRoots[1]) =
            _createValidValidatorData(maxAmount);
        amountsGwei[1] = maxAmount;

        uint256 totalValue = (minAmount + maxAmount) * 1_000_000_000;

        // Expect DepositEvent to be emitted
        vm.expectEmit(true, true, true, true);
        emit FigmentEth2DepositorV1.DepositEvent(address(this), 2, totalValue);

        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        // Verify mock deposit contract was called correctly
        assertEq(mockDepositContract.depositCount(), 2);
    }

    function test_Deposit_MixedValidAmounts_Success() public {
        bytes[] memory pubkeys = new bytes[](4);
        bytes[] memory withdrawalCredentials = new bytes[](4);
        bytes[] memory signatures = new bytes[](4);
        bytes32[] memory depositDataRoots = new bytes32[](4);
        uint256[] memory amountsGwei = new uint256[](4);

        uint256[] memory testAmounts = new uint256[](4);
        testAmounts[0] = 32_000_000_000; // Minimum
        testAmounts[1] = 100_000_000_000; // 100 ETH
        testAmounts[2] = 1000_000_000_000; // 1000 ETH
        testAmounts[3] = 2048_000_000_000; // Maximum

        uint256 totalValue = 0;
        for (uint256 i = 0; i < testAmounts.length; i++) {
            (pubkeys[i], withdrawalCredentials[i], signatures[i], depositDataRoots[i]) =
                _createValidValidatorData(testAmounts[i]);
            amountsGwei[i] = testAmounts[i];
            totalValue += testAmounts[i] * 1_000_000_000;
        }

        // Expect the MockDepositContract event FIRST (it's emitted first during deposit)
        vm.expectEmit(true, true, true, true);
        emit IDepositContract.DepositEvent( // Template
            pubkeys[0],
            withdrawalCredentials[0],
            abi.encodePacked(uint64(testAmounts[0])),
            signatures[0],
            abi.encodePacked(uint64(1))
        );

        vm.expectEmit(true, true, true, true);
        emit IDepositContract.DepositEvent( // Template
            pubkeys[1],
            withdrawalCredentials[1],
            abi.encodePacked(uint64(testAmounts[1])),
            signatures[1],
            abi.encodePacked(uint64(2))
        );

        vm.expectEmit(true, true, true, true);
        emit IDepositContract.DepositEvent( // Template
            pubkeys[2],
            withdrawalCredentials[2],
            abi.encodePacked(uint64(testAmounts[2])),
            signatures[2],
            abi.encodePacked(uint64(3))
        );

        vm.expectEmit(true, true, true, true);
        emit IDepositContract.DepositEvent( // Template
            pubkeys[3],
            withdrawalCredentials[3],
            abi.encodePacked(uint64(testAmounts[3])),
            signatures[3],
            abi.encodePacked(uint64(4))
        );

        vm.expectEmit(true, true, true, true);
        emit FigmentEth2DepositorV1.DepositEvent(address(this), 4, totalValue);

        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        assertEq(mockDepositContract.depositCount(), 4);
    }

    function test_Deposit_ZeroValueTransaction() public {
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 amountGwei = 32_000_000_000;
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(amountGwei);
        amountsGwei[0] = amountGwei;

        uint256 totalValue = amountGwei * 1_000_000_000;

        // Call with no ETH value
        vm.expectRevert(abi.encodeWithSelector(FigmentEth2DepositorV1.EthAmountMismatch.selector, 0, totalValue));
        figmentDepositor.deposit{value: 0}(pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei);
    }

    function test_Deposit_ContractBalanceAfterDeposit() public {
        uint256 initialBalance = address(figmentDepositor).balance;
        assertEq(initialBalance, 0);

        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 amountGwei = 32_000_000_000;
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(amountGwei);
        amountsGwei[0] = amountGwei;

        uint256 totalValue = amountGwei * 1_000_000_000;

        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        // Contract should have no balance after deposit (all ETH forwarded to deposit contract)
        assertEq(address(figmentDepositor).balance, 0);
    }

    // ============ Pause/Unpause Tests ============

    function test_Contract_InitiallyUnpaused() public view {
        assertFalse(figmentDepositor.paused());
    }

    function test_Pause_OwnerCanPause() public {
        assertFalse(figmentDepositor.paused());

        figmentDepositor.pause();

        assertTrue(figmentDepositor.paused());
    }

    function test_Pause_NonOwnerCannotPause() public {
        address nonOwner = address(0x123);
        vm.prank(nonOwner);

        vm.expectRevert();
        figmentDepositor.pause();
    }

    function test_Unpause_OwnerCanUnpause() public {
        figmentDepositor.pause();
        assertTrue(figmentDepositor.paused());

        figmentDepositor.unpause();

        assertFalse(figmentDepositor.paused());
    }

    function test_Unpause_NonOwnerCannotUnpause() public {
        figmentDepositor.pause();
        address nonOwner = address(0x123);
        vm.prank(nonOwner);

        vm.expectRevert();
        figmentDepositor.unpause();
    }

    function test_Deposit_WhenPaused_Reverts() public {
        figmentDepositor.pause();

        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(32_000_000_000);
        amountsGwei[0] = 32_000_000_000;

        vm.expectRevert(Pausable.EnforcedPause.selector);
        figmentDepositor.deposit{value: 32 ether}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );
    }

    function test_Deposit_AfterUnpause_Success() public {
        // Pause first
        figmentDepositor.pause();
        assertTrue(figmentDepositor.paused());

        // Unpause
        figmentDepositor.unpause();
        assertFalse(figmentDepositor.paused());

        // Now deposit should work
        bytes[] memory pubkeys = new bytes[](1);
        bytes[] memory withdrawalCredentials = new bytes[](1);
        bytes[] memory signatures = new bytes[](1);
        bytes32[] memory depositDataRoots = new bytes32[](1);
        uint256[] memory amountsGwei = new uint256[](1);

        uint256 amountGwei = 32_000_000_000;
        (pubkeys[0], withdrawalCredentials[0], signatures[0], depositDataRoots[0]) =
            _createValidValidatorData(amountGwei);
        amountsGwei[0] = amountGwei;

        uint256 totalValue = amountGwei * 1_000_000_000;

        vm.expectEmit(true, true, true, true);
        emit FigmentEth2DepositorV1.DepositEvent(address(this), 1, totalValue);

        figmentDepositor.deposit{value: totalValue}(
            pubkeys, withdrawalCredentials, signatures, depositDataRoots, amountsGwei
        );

        assertEq(mockDepositContract.depositCount(), 1);
    }

    // ============ Access Control Tests ============

    function test_Owner_IsCorrect() public view {
        assertEq(figmentDepositor.owner(), address(this));
    }

    function test_TransferOwnership() public {
        address newOwner = address(0x456);

        figmentDepositor.transferOwnership(newOwner);

        assertEq(figmentDepositor.owner(), newOwner);
    }

    function test_RenounceOwnership() public {
        figmentDepositor.renounceOwnership();

        assertEq(figmentDepositor.owner(), address(0));
    }

    function test_NewOwner_CanPauseAndUnpause() public {
        address newOwner = address(0x789);
        figmentDepositor.transferOwnership(newOwner);

        vm.prank(newOwner);
        figmentDepositor.pause();
        assertTrue(figmentDepositor.paused());

        vm.prank(newOwner);
        figmentDepositor.unpause();
        assertFalse(figmentDepositor.paused());
    }

    function test_OldOwner_CannotPauseAfterTransfer() public {
        address newOwner = address(0x999);
        figmentDepositor.transferOwnership(newOwner);

        // Old owner (this contract) should not be able to pause
        vm.expectRevert();
        figmentDepositor.pause();
    }
}
