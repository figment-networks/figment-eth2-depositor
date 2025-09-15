// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../contracts/interfaces/IDepositContract.sol";

contract FigmentEth2Depositor is Pausable, Ownable {

    /**
     * @dev Custom errors for better gas efficiency and debugging
     */
    error InsufficientAmount(uint256 provided, uint256 minimum);
    error EthAmountMismatch(uint256 provided, uint256 expected);
    error ParametersMismatch(uint256 expected, uint256 provided);
    error InvalidValidatorData(uint256 index, string field);
    error ZeroAddress();
    error DirectEthTransferNotAllowed();

    /**
     * @dev Eth2 Deposit Contract address.
     */
    IDepositContract public immutable depositContract;

    /**
     * @dev Minimal and maximum amount of nodes per transaction.
     */
    uint256 public constant nodesMinAmount = 1;
    uint256 public constant pubkeyLength = 48;
    uint256 public constant credentialsLength = 32;
    uint256 public constant signatureLength = 96;

    /**
     * @dev Collateral size of one node.
     */
    uint256 public constant collateral = 32 ether;

    /**
     * @dev Setting Eth2 Smart Contract address during construction.
     */
    constructor(address depositContract_) Ownable(msg.sender) {
        if (depositContract_ == address(0)) {
            revert ZeroAddress();
        }
        depositContract = IDepositContract(depositContract_);
    }

    /**
     * @dev This contract will not accept direct ETH transactions.
     */
    receive() external payable {
        revert DirectEthTransferNotAllowed();
    }

    /**
     * @dev Function that allows to deposit many nodes at once.
     *
     * - pubkeys                - Array of BLS12-381 public keys.
     * - withdrawal_credentials - Array of commitments to a public keys for withdrawals.
     * - signatures             - Array of BLS12-381 signatures.
     * - deposit_data_roots     - Array of the SHA-256 hashes of the SSZ-encoded DepositData objects.
     * - amounts                - Array of deposit amounts in wei for each validator.
     */
    function deposit(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots,
        uint256[] calldata amounts
    ) external payable whenNotPaused {

        uint256 nodesAmount = pubkeys.length;

        if (nodesAmount == 0) {
            revert ParametersMismatch(1, 0);
        }

        if (withdrawal_credentials.length != nodesAmount) {
            revert ParametersMismatch(nodesAmount, withdrawal_credentials.length);
        }
        if (signatures.length != nodesAmount) {
            revert ParametersMismatch(nodesAmount, signatures.length);
        }
        if (deposit_data_roots.length != nodesAmount) {
            revert ParametersMismatch(nodesAmount, deposit_data_roots.length);
        }
        if (amounts.length != nodesAmount) {
            revert ParametersMismatch(nodesAmount, amounts.length);
        }

        // Calculate total expected ETH amount
        uint256 totalAmount = 0;
        for (uint256 i; i < nodesAmount; ++i) {
            if (amounts[i] < collateral) {
                revert InsufficientAmount(amounts[i], collateral);
            }
            totalAmount += amounts[i];
        }

        if (msg.value != totalAmount) {
            revert EthAmountMismatch(msg.value, totalAmount);
        }

        for (uint256 i; i < nodesAmount; ++i) {
            if (pubkeys[i].length != pubkeyLength) {
                revert InvalidValidatorData(i, "pubkey");
            }
            if (withdrawal_credentials[i].length != credentialsLength) {
                revert InvalidValidatorData(i, "withdrawal_credentials");
            }
            if (signatures[i].length != signatureLength) {
                revert InvalidValidatorData(i, "signature");
            }

            IDepositContract(address(depositContract)).deposit{value: amounts[i]}(
                pubkeys[i],
                withdrawal_credentials[i],
                signatures[i],
                deposit_data_roots[i]
            );

        }

        emit DepositEvent(msg.sender, nodesAmount, totalAmount);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
      _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
      _unpause();
    }

    event DepositEvent(address from, uint256 nodesAmount, uint256 totalAmount);
}
