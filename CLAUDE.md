# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Solidity smart contract for batch Ethereum 2.0 validator deposits supporting variable amounts (1–2048 ETH per validator, up to 500 validators per transaction). Built with Hardhat 3 + Foundry dual-framework setup.

## Commands

```bash
# Install dependencies
pnpm install

# Run all tests (Forge + Node.js)
pnpm hardhat test

# Run only Solidity (Forge) tests
pnpm hardhat test solidity

# Run only Node.js tests
pnpm hardhat test nodejs

# Run a specific test file
pnpm hardhat test test/FigmentEth2DepositorV1.ts

# Deploy locally
pnpm hardhat ignition deploy ignition/modules/FigmentEth2DepositorV1.ts

# Deploy to Hoodi testnet (requires HOODI_PRIVATE_KEY in keystore)
pnpm hardhat keystore set HOODI_PRIVATE_KEY
pnpm hardhat ignition deploy --network hoodi ignition/modules/FigmentEth2DepositorV1.ts

# Contract verification (Hoodi)
forge build --force
forge verify-contract <address> contracts/FigmentEth2DepositorV1.sol:FigmentEth2DepositorV1 \
  --chain-id 560048 --etherscan-api-key <api-key> --constructor-args <encoded-args> \
  --optimizer-runs 200 --evm-version cancun --compiler-version 0.8.28 --watch
```

## Architecture

### Contracts

- **`FigmentEth2DepositorV1.sol`** — Main contract. Accepts batched validator deposit data and forwards each deposit to the canonical Eth2 deposit contract. Extends OpenZeppelin `Ownable2Step` + `Pausable`. Validates array lengths, per-validator amounts (in Gwei), and total ETH sent.
- **`FigmentEth2DepositorV0.sol`** — Legacy contract with fixed 32 ETH per validator. Kept for gas comparison.
- **`interfaces/IDepositContract.sol`** — Standard Eth2 deposit contract interface (defines `DepositEvent` and `deposit()`).
- **`MockDepositContract.sol`** — Test double for the Eth2 deposit contract.

Key constants in V1:
- `NODES_MAX_AMOUNT = 500` — cap per transaction
- `MIN_COLLATERAL_GWEI = 1_000_000_000` (1 ETH)
- `MAX_COLLATERAL_GWEI = 2_048_000_000_000` (2048 ETH)
- Pubkey: 48 bytes, credentials: 32 bytes, signature: 96 bytes

### Tests

Two parallel test suites:
1. **Forge** (`contracts/*.t.sol`) — unit tests covering constructor, deposit validation, revert cases, and multi-validator scenarios.
2. **Node.js** (`test/*.ts`) — integration-style tests using Hardhat + Viem. `GasComparison.ts` benchmarks V0 vs V1 across batch sizes.

Test utilities live in `test/utils/`: `testHelpers.ts` (validator data generation, gas measurement) and `gasReporter.ts` (cost analysis).

### Deployment

`ignition/modules/FigmentEth2DepositorV1.ts` uses Hardhat Ignition. The constructor takes the deposit contract address, which differs per network (mainnet, Sepolia, Hoodi).

### Toolchain

- Solidity 0.8.28, optimizer 200 runs, via-IR enabled, EVM version Cancun
- Hardhat 3 with `hardhat-toolbox-viem`; Viem for contract interaction in tests
- No npm scripts — all tasks run through `pnpm hardhat`
- Package is ESM (`"type": "module"`)
