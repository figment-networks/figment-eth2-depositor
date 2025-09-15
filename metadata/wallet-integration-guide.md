# Clear Signing Integration Guide

This guide helps wallet developers integrate clear signing support for the FigmentEth2Depositor contract.

## Overview

The FigmentEth2Depositor contract creates multiple Ethereum 2.0 validators in a single transaction with custom stake amounts. Clear signing should help users understand:

1. **What they're doing**: Creating Ethereum 2.0 validators
2. **How much they're staking**: Total ETH and per-validator amounts
3. **Where rewards go**: Withdrawal credentials interpretation
4. **Risks involved**: Lockup period, slashing, etc.

## Transaction Display Recommendations

### Primary Display
```
🔥 Create Ethereum 2.0 Validators

Validators: 3
Total Stake: 107 ETH
Individual Stakes: 32 ETH, 35 ETH, 40 ETH
```

### Detailed Breakdown
```
Validator 1:
  Stake: 32 ETH
  Public Key: 0x1234...abcd
  Withdrawal: Execution Address (0x5678...efgh)

Validator 2:
  Stake: 35 ETH
  Public Key: 0x2345...bcde
  Withdrawal: BLS Key (0x6789...fghi)

Validator 3:
  Stake: 40 ETH
  Public Key: 0x3456...cdef
  Withdrawal: Execution Address (0x789a...ghij)
```

### Risk Warnings
```
⚠️  Important Considerations:
• ETH will be locked until Ethereum 2.0 withdrawals are enabled
• Validators are subject to slashing conditions (potential loss)
• Minimum 32 ETH required per validator
• Invalid data may result in permanent loss
```

## Parameter Interpretation

### `amounts_gwei` (uint256[])
- **Display**: Convert to ETH by dividing by 1e9
- **Format**: "{value} ETH"
- **Validation**: Show warning if < 32 ETH or > 2048 ETH
- **Example**: `32000000000` → "32 ETH"

### `withdrawal_credentials` (bytes[])
- **First byte `0x00`**: "BLS Withdrawal Key"
- **First byte `0x01`**: "Execution Address: 0x{last 20 bytes}"
- **Format**: Truncate long addresses with "0x1234...abcd"

### `pubkeys` (bytes[])
- **Display**: "Validator Public Key"
- **Format**: "0x{first 8 chars}...{last 8 chars}"
- **Count**: Show total number of validators

### `signatures` (bytes[])
- **Display**: "Cryptographic Signature"
- **Format**: "0x{first 8 chars}...{last 8 chars}"
- **Note**: "Proves ownership of validator key"

### `deposit_data_roots` (bytes32[])
- **Display**: "Data Integrity Checksum"
- **Format**: "0x{first 8 chars}...{last 8 chars}"
- **Note**: "Verifies deposit data accuracy"

## Value Display

The transaction value should equal the sum of all `amounts_gwei` converted to wei:

```typescript
const totalWei = amounts_gwei.reduce((sum, gwei) => sum + (gwei * 1e9), 0);
const totalETH = totalWei / 1e18;
```

Display as: "Total Stake: {totalETH} ETH"

## Error Messages

### Common Validation Errors
- `InsufficientAmount`: "Deposit amount too low. Minimum 32 ETH per validator."
- `EthAmountMismatch`: "Transaction value doesn't match total stake amount."
- `ParametersMismatch`: "Mismatched array lengths. All arrays must have same length."
- `InvalidValidatorData`: "Invalid validator data at position {index}."

### Clear Error Display
```
❌ Transaction Failed
Reason: Deposit amount too low
Solution: Each validator requires at least 32 ETH
Your amount: 30 ETH (Validator #2)
```

## Gas Estimation

Provide gas estimates based on validator count:
- **Base cost**: ~73,000 gas
- **Per validator**: ~21,000 gas
- **Formula**: `73000 + (validator_count * 21000)`

## Integration Steps

1. **Detect Contract**: Identify FigmentEth2Depositor contract calls
2. **Parse Parameters**: Extract and validate function parameters
3. **Format Display**: Convert amounts, interpret credentials, show risks
4. **Validate Data**: Check array lengths, amount limits, value matching
5. **Show Summary**: Clear overview of validators being created
6. **Confirm Risks**: Ensure user understands lockup and slashing

## Testing

Test with these scenarios:
- Single validator (32 ETH)
- Multiple validators with same amounts
- Multiple validators with different amounts
- Mixed withdrawal credential types
- Edge cases (minimum/maximum amounts)
- Error conditions (mismatched arrays, insufficient amounts)

## Metadata Location

- JSON descriptors: `/metadata/clear-signing-descriptor.json`
- Human-readable ABI: `/metadata/human-readable-abi.json`
- This guide: `/metadata/wallet-integration-guide.md`
