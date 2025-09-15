# Figment Ethereum Deposit Contracts

## Installation

1. Clone the repository `git clone git@github.com:figment-networks/figment-eth2-depositor.git`
2. Install the npm dependencies `pnpm install`


## Usage

### Running Tests

To run all the tests in the project, execute the following command:

```shell
pnpm hardhat test
```

You can also selectively run the Solidity or `node:test` tests:

```shell
pnpm hardhat test solidity
pnpm hardhat test nodejs
```

### Make a deployment to Sepolia

This project includes an example Ignition module to deploy the contract. You can deploy this module to a locally simulated chain or to Sepolia.

To run the deployment to a local chain:

```shell
pnpm hardhat ignition deploy ignition/modules/FigmentEth2Depositor.ts
```

To run the deployment to Sepolia, you need an account with funds to send the transaction. The provided Hardhat configuration includes a Configuration Variable called `SEPOLIA_PRIVATE_KEY`, which you can use to set the private key of the account you want to use.

You can set the `SEPOLIA_PRIVATE_KEY` variable using the `hardhat-keystore` plugin or by setting it as an environment variable.

To set the `SEPOLIA_PRIVATE_KEY` config variable using `hardhat-keystore`:

```shell
pnpm hardhat keystore set SEPOLIA_PRIVATE_KEY
```

After setting the variable, you can run the deployment with the Sepolia network:

```shell
pnpm hardhat ignition deploy --network sepolia ignition/modules/Counter.ts
```


## License

MIT


## FigmentEth2Depositor Contract

The Figment Eth2 Depositor provides a convenient way to send 1 or more deposits in one transaction to the Eth2 Deposit Contract.

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
