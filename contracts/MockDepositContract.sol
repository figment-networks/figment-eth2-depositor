// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../contracts/interfaces/IDepositContract.sol";

/**
 * @dev Mock deposit contract for testing gas costs
 * This contract accepts deposits without reverting, allowing accurate gas measurement
 */
contract MockDepositContract is IDepositContract {
    uint256 public depositCount;

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 /* deposit_data_root */
    ) external payable override {
        // Basic validation to simulate real contract work
        require(pubkey.length == 48, "Invalid pubkey length");
        require(withdrawal_credentials.length == 32, "Invalid withdrawal credentials length");
        require(signature.length == 96, "Invalid signature length");
        require(msg.value >= 1 ether, "Deposit value too low");
        require(msg.value % 1 gwei == 0, "Deposit value not multiple of gwei");

        // Simulate deposit contract work
        depositCount++;

        // Emit event to simulate real contract behavior
        emit DepositEvent(
            pubkey,
            withdrawal_credentials,
            abi.encodePacked(uint64(msg.value / 1 gwei)),
            signature,
            abi.encodePacked(uint64(depositCount))
        );
    }

    function get_deposit_root() external pure override returns (bytes32) {
        return keccak256("mock_root");
    }

    function get_deposit_count() external view override returns (bytes memory) {
        return abi.encodePacked(uint64(depositCount));
    }
}
