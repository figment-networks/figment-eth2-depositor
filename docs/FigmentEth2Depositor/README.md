## FigmentEth2Depositor Contract

The Figment Eth2 Depositor provides a convenient way to send 1 or more deposits in one transaction to the Eth2 Deposit Contract when the deposit amount is 32 ETH for each validator.

### Contract Addresses

- Contract address on mainnet: `0x00000000219ab540356cBB839Cbe05303d7705Fa`
- Contract address on (Hoodi) testnet: `0x00000000219ab540356cBB839Cbe05303d7705Fa`

Below is a list of contracts we use for this service:

<dl>
  <dt>Ownable, Pausable</dt>
  <dd>OpenZepellin smart contracts. The first contract allows for managing ownership. The second contract allows for pausing the contract and vice versa.</dd>
</dl>

<dl>
  <dt>FigmentEth2Depositor</dt>
  <dd>A smart contract that accepts X amount of ETH and sends {x / 32} transactions with required collateral (32 ETH) to the Eth2 Deposit Contract.</dd>
</dl>

### How to Use

1. Choose the amount of Eth2 validator nodes you want to deposit to.
2. Instantiate those validators with your chosen `withdrawal_credentials`
3. Retrieve your validators' `pubkeys`, and generate `deposit_signatures` and `deposit_data_roots` from each that will let you deposit to them.
4. Use the _deposit()_ function on `FigmentEth2Depositor` with the required ETH value to make the deposits to the Eth2 Deposit Contract.
