// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../contracts/interfaces/IDepositContract.sol";

contract FigmentEth2Depositor is ReentrancyGuard, Pausable, Ownable {

    /**
     * @dev Eth2 Deposit Contract address.
     */
    IDepositContract public depositContract;

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
    constructor(bool mainnet, address depositContract_) {
        if (mainnet == true) {
            depositContract = IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
        } else if (depositContract_ == 0x0000000000000000000000000000000000000000) {
            depositContract = IDepositContract(0x8c5fecdC472E27Bc447696F431E425D02dd46a8c);
        } else {
            depositContract = IDepositContract(depositContract_);
        }
    }

    /**
     * @dev This contract will not accept direct ETH transactions.
     */
    receive() external payable {
        revert("Do not send ETH here");
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

        require(nodesAmount > 0 && nodesAmount <= 100, "100 nodes max / tx");
        require(msg.value == collateral * nodesAmount, "ETH amount missmatch");


        require(
            withdrawal_credentials.length == nodesAmount &&
            signatures.length == nodesAmount &&
            deposit_data_roots.length == nodesAmount,
            "Paramters missmatch");

        for (uint256 i = 0; i < nodesAmount; ++i) {
            require(pubkeys[i].length == pubkeyLength, "Wrong pubkey");
            require(withdrawal_credentials[i].length == credentialsLength, "Wrong withdrawal cred");
            require(signatures[i].length == signatureLength, "Wrong signatures");

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
    function pause() public onlyOwner {
      _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner {
      _unpause();
    }

    event DepositEvent(address from, uint256 nodesAmount);
}
