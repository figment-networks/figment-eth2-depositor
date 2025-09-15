# Analysis and Monitoring Scripts

This directory contains scripts for gas analysis and event monitoring for the FigmentEth2Depositor contracts.

## Scripts Overview

### 1. `analyze-gas.ts`
**Gas cost comparison between new and legacy contracts**

Analyzes and compares gas costs between the new `FigmentEth2Depositor` (variable amounts) and legacy `FigmentEth2Depositor0x01` (fixed 32 ETH) contracts. Provides detailed gas usage reports with cost calculations.

```bash
# Run gas analysis comparison
npx hardhat run scripts/analyze-gas.ts
```

**Features:**
- Deploys mock contracts for testing
- Compares single and multiple validator scenarios
- Shows gas usage, percentage differences, and USD cost estimates
- Uses configurable gas price and ETH price for cost calculations

### 2. `demo-event-monitoring.ts`
**Interactive demo of event monitoring**

Deploys test contracts, makes a deposit transaction, and demonstrates how to monitor the resulting events.

```bash
# Run the interactive demo
npx hardhat run scripts/demo-event-monitoring.ts
```

## Example Outputs

### Gas Analysis Output
```
🔥 Gas Analysis Tool 🔥

✅ Mock Deposit Contract deployed at: 0x5fbdb...
✅ New Contract deployed at: 0xe7f17...
✅ Legacy Contract deployed at: 0x9fe46...

📊 Single Validator
──────────────────────────────────────────────────
Legacy Gas:     71,223 gas
New Gas:        72,756 gas
Difference:     +1,533 gas
% Change:       +2.00%
🔴 Gas Increase: 1,533 gas
💸 Cost Increase: $0.091980

📊 Multiple Validators (5)
──────────────────────────────────────────────────
Using gwei amounts: [32, 34, 36, 38, 40] ETH
Legacy Gas:     153,471 gas
New Gas:        157,068 gas
Difference:     +3,597 gas
% Change:       +2.00%
🔴 Gas Increase: 3,597 gas
💸 Cost Increase: $0.215820

✅ Gas analysis complete!
```

### Event Monitoring Output
```
🔸 Deposit Event #1
────────────────────────────────────────
Contract:   0x5fbdb2315678afecb367f032d93f642f64180aa3
Validator Index: 1
Amount:     32000000000 gwei (32 ETH)
Pubkey:     0x1234...abcd
Withdrawal: 0x01234...5678
Signature:  0xabcd...1234
────────────────────────────────────────

🔸 Figment Event #1
────────────────────────────────────────
Contract:    0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
From:        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Nodes:       3
Total:       107000000000000000000 wei (107 ETH)
────────────────────────────────────────
```

## Event Data Structure

The Ethereum 2.0 deposit contract emits `DepositEvent` with these fields:

```solidity
event DepositEvent(
    bytes pubkey,                 // BLS public key (48 bytes)
    bytes withdrawal_credentials, // Withdrawal credentials (32 bytes)
    bytes amount,                 // Deposit amount in gwei (8 bytes, little-endian)
    bytes signature,              // BLS signature (96 bytes)
    bytes index                   // Validator index (8 bytes, little-endian)
);
```

The Figment contract also emits its own event:

```solidity
event DepositEvent(
    address from,       // Address that made the deposit
    uint256 nodesAmount, // Number of validators
    uint256 totalAmount  // Total ETH amount in wei
);
```

## Use Cases

### 1. **Gas Cost Analysis**
Use `analyze-gas.ts` to compare gas costs between different contract implementations and validate optimization decisions.

### 2. **Transaction Verification**
Use `demo-event-monitoring.ts` to verify that deposits emit the correct events and understand how event parsing works.

### 3. **Development and Testing**
Both scripts help during development to:
- Validate contract behavior
- Understand gas implications of design decisions
- Test event emission and parsing
- Compare different implementations

### 4. **Integration Testing**
The demo script shows how to integrate event monitoring into your applications for real-time tracking of deposit operations.

## Configuration

Both scripts use your Hardhat network configuration. For mainnet use, ensure you have:
- Proper RPC endpoint configuration
- Sufficient ETH for gas fees (analyze-gas.ts deploys contracts)
- Appropriate gas price settings

The gas analysis uses configurable parameters:
- Gas price: 20 gwei (configurable in GasReporter)
- ETH price: $3000 (configurable in GasReporter)

## Integration

These scripts can be integrated into:
- CI/CD pipelines for gas regression testing
- Development workflows for contract validation
- Monitoring systems for production deployments
- Analytics dashboards for cost tracking
