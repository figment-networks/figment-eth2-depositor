# Event Monitoring Scripts

This directory contains scripts for monitoring and analyzing deposit events from the Ethereum 2.0 deposit contract.

## Scripts Overview

### 1. `monitor-deposit-events.ts`
**Real-time event monitoring with filtering capabilities**

Monitor deposit events from the Ethereum 2.0 deposit contract in real-time. Can filter events to only show those originating from your Figment contract.

```bash
# Monitor all deposit events from mainnet
npx hardhat run scripts/monitor-deposit-events.ts

# Monitor only events from your deployed Figment contract
npx hardhat run scripts/monitor-deposit-events.ts \
  --figment-contract=0x123... \
  --from-block=19000000

# Monitor mock contract for testing
npx hardhat run scripts/monitor-deposit-events.ts \
  --deposit-contract=0x456... \
  --figment-contract=0x789...
```

**Options:**
- `--deposit-contract=ADDRESS` - Deposit contract to monitor (default: mainnet)
- `--figment-contract=ADDRESS` - Filter events only from this Figment contract
- `--from-block=NUMBER` - Start monitoring from this block (default: 0)
- `--help` - Show help message

### 2. `check-transaction-events.ts`
**Analyze events from a specific transaction**

Check what deposit events were emitted by a specific transaction. Useful for verifying deposits after making a transaction.

```bash
# Check events from a specific transaction
npx hardhat run scripts/check-transaction-events.ts 0x1234567890abcdef...
```

### 3. `demo-event-monitoring.ts`
**Interactive demo of event monitoring**

Deploys test contracts, makes a deposit transaction, and demonstrates how to monitor the resulting events.

```bash
# Run the interactive demo
npx hardhat run scripts/demo-event-monitoring.ts
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

Your Figment contract also emits its own event:

```solidity
event DepositEvent(
    address from,       // Address that made the deposit
    uint256 nodesAmount, // Number of validators
    uint256 totalAmount  // Total ETH amount in wei
);
```

## Use Cases

### 1. **Transaction Verification**
After making deposits through your Figment contract, use `check-transaction-events.ts` to verify that the correct number of deposit events were emitted.

### 2. **Real-time Monitoring**
Use `monitor-deposit-events.ts` with filtering to track when your contract makes deposits to the beacon chain.

### 3. **Analytics and Reporting**
Parse the event data to build analytics on your staking operations:
- Track total ETH staked
- Monitor validator indices
- Verify withdrawal credentials

### 4. **Debugging**
When transactions fail or behave unexpectedly, check the events to understand what happened.

## Example Output

```
🔸 New Deposit Event
──────────────────────────────────────────────────
Block:      19234567
Tx Hash:    0x1234...abcd
Log Index:  42
Validator Index: 12345
Amount:     32000000000 gwei (32 ETH)
Pubkey:     0x1234...abcd
Withdrawal: 0x01234...5678
Signature:  0xabcd...1234
──────────────────────────────────────────────────
```

## Network Configuration

The scripts automatically use the network configuration from your Hardhat config. Make sure you have the appropriate network settings for:

- **Mainnet**: Monitor real deposit contract (`0x00000000219ab540356cBB839Cbe05303d7705Fa`)
- **Testnet**: Monitor testnet deposit contracts
- **Local**: Monitor your deployed mock contracts

## Tips

1. **Gas Costs**: Monitoring events is read-only and doesn't cost gas
2. **Rate Limits**: Be mindful of RPC rate limits when monitoring mainnet
3. **Block Ranges**: Use `--from-block` to avoid scanning the entire chain
4. **Filtering**: Always filter by your contract address to reduce noise
5. **Real-time**: The monitor script runs continuously until you press Ctrl+C

## Integration

These scripts can be integrated into:
- CI/CD pipelines for testing
- Monitoring dashboards
- Alert systems
- Data analytics platforms
- Validator management tools
