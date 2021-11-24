// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../contracts/interfaces/IDepositContract.sol";

contract FigmentEth2Depositor is Pausable, Ownable {

    /**
     * @dev Eth2 Deposit Contract address.
     */
    IDepositContract public immutable depositContract;

    /**
     * @dev Minimal and maximum amount of nodes per transaction.
     */
    uint256 public constant nodesMinAmount = 1;
    uint256 public constant nodesMaxAmount = 100;
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
    constructor(address depositContract_) {
        require(depositContract_ != address(0), "Zero address");
        depositContract = IDepositContract(depositContract_);
    }

    /**
     * @dev This contract will not accept direct ETH transactions.
     */
    receive() external payable {
        revert("FigmentEth2Depositor: do not send ETH directly here");
    }

    /**
     * @dev Function that allows to deposit up to 100 nodes at once.
     *
     * - pubkeys                - Array of BLS12-381 public keys.
     * - withdrawal_credentials - Array of commitments to a public keys for withdrawals.
     * - signatures             - Array of BLS12-381 signatures.
     * - deposit_data_roots     - Array of the SHA-256 hashes of the SSZ-encoded DepositData objects.
     */
    function deposit(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external payable whenNotPaused {

        uint256 nodesAmount = pubkeys.length;

        require(nodesAmount > 0 && nodesAmount <= 100, "FigmentEth2Depositor: you can deposit only 1 to 100 nodes per transaction");
        require(msg.value == collateral * nodesAmount, "FigmentEth2Depositor: the amount of ETH does not match the amount of nodes");


        require(
            withdrawal_credentials.length == nodesAmount &&
            signatures.length == nodesAmount &&
            deposit_data_roots.length == nodesAmount,
            "FigmentEth2Depositor: amount of parameters do no match");

        for (uint256 i; i < nodesAmount; ++i) {
            require(pubkeys[i].length == pubkeyLength, "FigmentEth2Depositor: wrong pubkey");
            require(withdrawal_credentials[i].length == credentialsLength, "FigmentEth2Depositor: wrong withdrawal credentials");
            require(signatures[i].length == signatureLength, "FigmentEth2Depositor: wrong signatures");

            IDepositContract(address(depositContract)).deposit{value: collateral}(
                pubkeys[i],
                withdrawal_credentials[i],
                signatures[i],
                deposit_data_roots[i]
            );

        }

        emit DepositEvent(msg.sender, nodesAmount);
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

    event DepositEvent(address from, uint256 nodesAmount);
}
