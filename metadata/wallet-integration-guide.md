# ERC-7730 Clear Signing Integration Guide

This guide helps wallet developers integrate ERC-7730 compliant clear signing support for the FigmentEth2DepositorV1 contract.

## Overview

The FigmentEth2DepositorV1 contract creates multiple Ethereum 2.0 validators in a single transaction with custom stake amounts. This guide provides ERC-7730 standard implementation details for enhanced clear signing. The ERC-7730 format provides standardized metadata that helps users understand:

1. **What they're doing**: Creating Ethereum 2.0 validators
2. **How much they're staking**: Total ETH and per-validator amounts
3. **Where rewards go**: Withdrawal credentials interpretation
4. **Risks involved**: Lockup period, slashing, etc.

## ERC-7730 Standard Compliance

This implementation follows the [ERC-7730 draft specification](https://github.com/LedgerHQ/clear-signing-erc7730-registry/blob/master/specs/erc-7730.md) for standardized clear signing descriptors. The specification provides:

- **Context Binding**: Ensures descriptors are applied only to relevant transactions
- **Display Formats**: Standardized field formatting and labeling
- **Intent Declarations**: Human-readable transaction purposes
- **Security Considerations**: Protection against malicious descriptor attacks

## ERC-7730 Descriptor Integration

### Descriptor Location
The ERC-7730 descriptor is located at:
- **File**: `/metadata/clear-signing-descriptor.json`
- **Schema**: `https://raw.githubusercontent.com/LedgerHQ/clear-signing-erc7730-registry/master/schemas/erc7730.schema.json`

### Intent-Based Display
The ERC-7730 intent provides high-level transaction understanding:
```
Stake {{amounts_gwei.length}} validators with total {{msg.value}} ETH on Ethereum 2.0
```

This resolves to user-friendly text like:
```
🔥 Stake 3 validators with total 107 ETH on Ethereum 2.0
```

### Field-Level Display Formatting

The descriptor defines how each parameter should be displayed:

#### Primary Fields
```json
{
  "path": "amounts_gwei.length",
  "label": "Validators",
  "format": "validator_count"
}
```

#### Amount Formatting
```json
{
  "path": "msg.value",
  "label": "Total Stake",
  "format": "gwei_to_eth"
}
```

#### Array Field Display
```json
{
  "path": "amounts_gwei.*",
  "label": "Individual Stakes",
  "format": "gwei_to_eth"
}
```

### Recommended Display Layout
```
🔥 Stake 3 validators with total 107 ETH on Ethereum 2.0

Validators: 3
Total Stake: 107 ETH
Individual Stakes: 32 ETH, 35 ETH, 40 ETH

Validator Keys:
  0x1234...abcd
  0x2345...bcde
  0x3456...cdef

Withdrawal Addresses:
  0x5678...efgh (Execution Address)
  0x6789...fghi (BLS Key)
  0x789a...ghij (Execution Address)
```

### Security Warnings
ERC-7730 descriptors include standardized warnings:
```
⚠️  Security Considerations:
• ETH will be locked until Ethereum 2.0 withdrawals are enabled
• Validators are subject to slashing conditions
• Minimum 32 ETH required per validator
• Invalid validator data may result in permanent loss
```

## ERC-7730 Format Specifications

### Currency Amount Formatting
```json
"gwei_to_eth": {
  "type": "amount",
  "currency": {
    "type": "native"
  },
  "multiplier": "1000000000"
}
```
- Converts gwei values to ETH display
- Example: `32000000000` → "32 ETH"

### Raw Data Formatting
```json
"validator_pubkey": {
  "type": "raw",
  "params": {
    "encoding": "bytes48"
  }
}
```
- Formats 48-byte BLS public keys
- Display: "0x{first_8_chars}...{last_8_chars}"

### Withdrawal Credentials
```json
"withdrawal_credentials": {
  "type": "raw",
  "params": {
    "encoding": "bytes32"
  }
}
```
- **First byte `0x00`**: BLS Withdrawal Key
- **First byte `0x01`**: Execution Address (last 20 bytes)

### Signature Data
```json
"signature": {
  "type": "raw",
  "params": {
    "encoding": "bytes96"
  }
}
```
- Formats 96-byte BLS signatures
- Purpose: Proves validator key ownership

### Data Roots
```json
"data_root": {
  "type": "raw",
  "params": {
    "encoding": "bytes32"
  }
}
```
- Formats 32-byte Merkle roots
- Purpose: Verifies deposit data integrity

## Value Display

The transaction value should equal the sum of all `amounts_gwei` converted to wei:

```typescript
const totalWei = amounts_gwei.reduce((sum, gwei) => sum + (gwei * 1e9), 0);
const totalETH = totalWei / 1e18;
```

Display as: "Total Stake: {totalETH} ETH"

## Error Messages

### Common Validation Errors
- `InsufficientAmount`: "Deposit amount too low. Minimum 1 ETH per validator."
- `EthAmountMismatch`: "Transaction value doesn't match total stake amount."
- `ParametersMismatch`: "Mismatched array lengths. All arrays must have same length."
- `InvalidValidatorData`: "Invalid validator data at position {index}."

### Clear Error Display
```
❌ Transaction Failed
Reason: Deposit amount too low
Solution: Each validator requires at least 1 ETH
Your amount: 30 ETH (Validator #2)
```

## Gas Estimation

Provide gas estimates based on validator count:
- **Base cost**: ~73,000 gas
- **Per validator**: ~21,000 gas
- **Formula**: `73000 + (validator_count * 21000)`

## ERC-7730 Integration Steps

### 1. Descriptor Loading
```typescript
// Load the ERC-7730 descriptor
const descriptor = await fetch('/metadata/clear-signing-descriptor.json');
const erc7730 = await descriptor.json();

// Validate against schema
const isValid = validateERC7730Schema(erc7730);
```

### 2. Context Verification
```typescript
// Verify the contract matches the descriptor context
const contractMatch = erc7730.context.contract.deployments.find(
  deployment => deployment.chainId === currentChainId &&
                deployment.address === transactionTo
);
```

### 3. Intent Resolution
```typescript
// Resolve the intent template
const intent = erc7730.display.intent.deposit;
const resolvedIntent = intent
  .replace('{{amounts_gwei.length}}', amounts_gwei.length)
  .replace('{{msg.value}}', formatEth(msg.value));
```

### 4. Field Formatting
```typescript
// Apply field formatting rules
const fields = erc7730.display.fields.deposit;
const formattedFields = fields.map(field => ({
  label: field.label,
  value: formatFieldValue(field.path, field.format, transactionData)
}));
```

### 5. Security Validation
```typescript
// Display warnings from descriptor
const warnings = erc7730.security.warnings;
const riskLevel = erc7730.security.risk_level; // "high"
```

### 6. Legacy Fallback
```typescript
// Fallback to human-readable ABI if ERC-7730 not supported
if (!supportsERC7730) {
  const legacyAbi = await fetch('/metadata/human-readable-abi.json');
  // Use legacy_parameter_formatting section
}
```

## Testing & Validation

### ERC-7730 Validation
```bash
# Install the ERC-7730 validation tool
pip install erc7730

# Validate the descriptor
erc7730 lint metadata/clear-signing-descriptor.json

# Generate preview
erc7730 preview metadata/clear-signing-descriptor.json
```

### Test Scenarios
Test ERC-7730 integration with these scenarios:
- Single validator (32 ETH)
- Multiple validators with same amounts
- Multiple validators with different amounts
- Mixed withdrawal credential types (0x00 vs 0x01)
- Edge cases (minimum 32 ETH, maximum 2048 ETH)
- Error conditions (mismatched arrays, insufficient amounts)
- Large batches (approaching 500 validator limit)

### Descriptor Testing
```typescript
// Test intent resolution
const testIntent = resolveIntent(
  "Stake {{amounts_gwei.length}} validators with total {{msg.value}} ETH",
  { amounts_gwei: [32000000000, 40000000000], msg: { value: "72000000000000000000" }}
);
// Expected: "Stake 2 validators with total 72 ETH on Ethereum 2.0"

// Test field formatting
const testAmount = formatField("amounts_gwei.*", "gwei_to_eth", [32000000000]);
// Expected: ["32 ETH"]
```

## File Structure & Registry Submission

### Metadata Files
- **ERC-7730 Descriptor**: `/metadata/clear-signing-descriptor.json`
- **Human-readable ABI**: `/metadata/human-readable-abi.json`
- **Integration Guide**: `/metadata/wallet-integration-guide.md`

### Registry Submission
To submit to the [ERC-7730 registry](https://github.com/LedgerHQ/clear-signing-erc7730-registry):

1. **Fork the registry repository**
2. **Add your descriptor** to the appropriate directory structure
3. **Update deployment addresses** in the descriptor
4. **Submit a pull request** with validation passing
5. **Follow community review process**

### ABI URL Configuration
Update the ABI URL in the descriptor once published:
```json
"abi": {
  "url": "https://raw.githubusercontent.com/figment-networks/figment-eth2-depositor/main/artifacts/contracts/FigmentEth2DepositorV1.sol/FigmentEth2DepositorV1.json"
}
```

### Version Management
- Update `metadata.version` when making changes
- Maintain backward compatibility when possible
- Document breaking changes in release notes

## Migration from Legacy Format

Wallets should implement graceful fallback:
1. **Try ERC-7730 descriptor first** for enhanced display
2. **Fall back to human-readable ABI** for basic formatting
3. **Use raw ABI** as final fallback
4. **Cache descriptors** to improve performance

Legacy format fields are preserved in `legacy_parameter_formatting` for compatibility during transition period.
