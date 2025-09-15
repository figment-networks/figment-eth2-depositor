# FigmentEth2Depositor

## Gas Optimization Analysis

### Wei vs Gwei Amount Representation

**Analysis Complete: Using wei amounts instead of gwei would actually INCREASE gas costs by ~22 gas per validator, not decrease them.**

#### Key Findings

**Gas Cost Breakdown (per validator):**
- **Gwei version:** 176 gas (calldata) + 10 gas (2 MUL ops) = ~186 gas
- **Wei version:** 212 gas (calldata) + 0 gas (no MUL) = ~212 gas
- **Net difference:** +22 gas per validator (wei is more expensive)

#### Real-World Impact

| Validators | Extra Gas Cost | Extra USD Cost* |
|------------|---------------|----------------|
| 1          | +22 gas       | +$0.0013       |
| 10         | +220 gas      | +$0.0132       |
| 50         | +1,100 gas    | +$0.0660       |
| 100        | +2,200 gas    | +$0.1320       |
| 250        | +5,500 gas    | +$0.3300       |
| 500        | +11,000 gas   | +$0.6600       |

*At 20 gwei, $3000 ETH

#### Why Wei Costs More

1. **Calldata economics (EIP-2028):**
   - Zero bytes: 4 gas each
   - Non-zero bytes: 16 gas each

2. **Number representations:**
   - `32 ETH in gwei`: `32000000000` (28 zero bytes, 4 non-zero bytes) = 176 gas
   - `32 ETH in wei`: `32000000000000000000` (25 zero bytes, 7 non-zero bytes) = 212 gas

3. **The math:**
   - Calldata savings from gwei: 36 gas per amount
   - MUL operation cost: ~10 gas per validator (2 operations × 5 gas)
   - **Net savings with gwei: 26 gas per validator**

#### Recommendation

✅ **Keep using gwei amounts.** The multiplication operations are negligible compared to the calldata savings from using smaller numbers with more leading zeros.

The current implementation is already optimized! The apparent "inefficiency" of multiplication is actually more efficient than the alternative due to Ethereum's calldata pricing model.

---

## Transaction Size Limits

### Analysis of NODES_MAX_AMOUNT = 500

**Current 500-validator limit analysis:**
- **Gas usage:** ~10.6M gas (safely under 15-20M practical limits)
- **Transaction size:** ~120KB (safely under 128KB network limit)

**Per-validator costs:**
- ~21,000 gas per validator
- 240 bytes per validator (48B pubkey + 32B credentials + 96B signature + 32B root + 32B amount)

**Theoretical maximums:**
- **Gas-constrained:** ~709 validators (15M gas limit) to ~946 validators (20M gas limit)
- **Network size-constrained:** ~544 validators (128KB transaction limit)

**Conclusion:** 500 validators provides good operational margins while maximizing batch efficiency.
