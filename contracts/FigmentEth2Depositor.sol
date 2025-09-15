// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

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
     * @dev Maximum amount of nodes per transaction.
     *
     * Analysis shows 250 validators is conservative and safe:
     * - Gas usage: ~5.3M gas (well under 15-20M practical limits)
     * - Transaction size: ~60KB (well under 128KB network limit)
     * - Theoretical maximums: ~544 validators (size) or ~709+ validators (gas)
     *
     * We set the limit as 500 to be safe. That's a max of 1,024,000 ETH in one txn.
     */
    uint256 public constant NODES_MAX_AMOUNT = 500;
    uint256 public constant PUBKEY_LENGTH = 48;
    uint256 public constant CREDENTIALS_LENGTH = 32;
    uint256 public constant SIGNATURE_LENGTH = 96;

    /**
     * @dev Gwei to wei conversion factor.
     */
    uint256 public constant GWEI_TO_WEI = 1 gwei; // 1e9

    /**
     * @dev Minimum collateral in gwei
     */
    uint256 public constant MIN_COLLATERAL_GWEI = 32 ether;

    /**
     * @dev Maximum collateral in gwei based on Ethereum protocol limits.
     * No validator can accept a deposit greater than 2048 ETH.
     */
    uint256 public constant MAX_COLLATERAL_GWEI = 2048 ether;

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
     * - amounts_gwei            - Array of deposit amounts in gwei for each validator.
     */
    function deposit(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots,
        uint256[] calldata amounts_gwei
    ) external payable whenNotPaused {

        uint256 nodesAmount = pubkeys.length;

        // Gas optimization: Validate validator count bounds
        if (nodesAmount == 0 || nodesAmount > NODES_MAX_AMOUNT) {
            revert ParametersMismatch(nodesAmount, NODES_MAX_AMOUNT);
        }

        // Gas optimization: Combined length validation to reduce multiple checks
        if (withdrawal_credentials.length != nodesAmount ||
            signatures.length != nodesAmount ||
            deposit_data_roots.length != nodesAmount ||
            amounts_gwei.length != nodesAmount) {
            revert ParametersMismatch(nodesAmount, 0); // Use 0 as generic mismatch indicator
        }

        // Note: totalAmount overflow is mathematically impossible within practical limits:
        // Max per validator: 2048 ETH (~2e21 wei) × Max validators: 250 = ~5e23 wei << uint256.max (~1e77)
        uint256 totalAmount;
        unchecked {
            for (uint256 i; i < nodesAmount; ++i) {
                uint256 amountGwei = amounts_gwei[i];

                // Validate amounts first (most likely to fail fast)
                if (amountGwei < MIN_COLLATERAL_GWEI) {
                    revert InsufficientAmount(amountGwei, MIN_COLLATERAL_GWEI);
                }
                if (amountGwei > MAX_COLLATERAL_GWEI) {
                    revert InsufficientAmount(amountGwei, MAX_COLLATERAL_GWEI);
                }

                 // TODO: check if 0x01 and max of 32 ETH ??

                // Validate data lengths
                if (pubkeys[i].length != PUBKEY_LENGTH) {
                    revert InvalidValidatorData(i, "pubkey");
                }
                if (withdrawal_credentials[i].length != CREDENTIALS_LENGTH) {
                    revert InvalidValidatorData(i, "withdrawal_credentials");
                }
                if (signatures[i].length != SIGNATURE_LENGTH) {
                    revert InvalidValidatorData(i, "signature");
                }

                // Calculate total (overflow impossible with reasonable validator counts)
                totalAmount += amountGwei * GWEI_TO_WEI;
            }
        }


        if (msg.value != totalAmount) {
            revert EthAmountMismatch(msg.value, totalAmount);
        }

        // Gas optimization: Deposit loop with unchecked arithmetic where safe
        // Cache deposit contract to avoid repeated SLOAD
        IDepositContract cachedDepositContract = depositContract;
        unchecked {
            for (uint256 i; i < nodesAmount; ++i) {
                // Safe due to MAX_COLLATERAL_GWEI validation above
                uint256 amountWei = amounts_gwei[i] * GWEI_TO_WEI;

                cachedDepositContract.deposit{value: amountWei}(
                    pubkeys[i],
                    withdrawal_credentials[i],
                    signatures[i],
                    deposit_data_roots[i]
                );
            }
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
