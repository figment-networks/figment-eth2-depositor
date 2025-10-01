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

### Make a deployment

This project includes an example Ignition module to deploy the contract. You can deploy this module to a locally simulated chain or to Hoodi.

To run the deployment to a local chain:

```shell
pnpm hardhat ignition deploy ignition/modules/FigmentEth2DepositorV1.ts
```

To run the deployment to Hoodi, you need an account with funds to send the transaction. The provided Hardhat configuration includes a Configuration Variable called `HOODI_PRIVATE_KEY`, which you can use to set the private key of the account you want to use.

You can set the `HOODI_PRIVATE_KEY` variable using the `hardhat-keystore` plugin or by setting it as an environment variable.

To set the `HOODI_PRIVATE_KEY` config variable using `hardhat-keystore`:

```shell
pnpm hardhat keystore set HOODI_PRIVATE_KEY
```

After setting the variable, you can run the deployment with the Sepolia network:

```shell
pnpm hardhat ignition deploy --network hoodi ignition/modules/FigmentEth2DepositorV1.ts
```

### Verification on hoodi.etherscan
In order to verify a deployed contract on etherscan you need to 
1. get a free etherscan api key `<ether-scan-api-key>`
2. Ensure the compile version of the deployed contract matches the versions in your `foundry.toml`
3. Run the command `forge build --force`
4. (Assuming that contract was compiled with version 0.8.28) run the command:
```
forge verify-contract <deployed-contract-address> contracts/FigmentEth2DepositorV1.sol:FigmentEth2DepositorV1 --chain-id 560048 --etherscan-api-key <ether-scan-api-key> --constructor-args 0x00000000000000000000000000000000219ab540356cbb839cbe05303d7705fa --optimizer-runs 200 --evm-version cancun --compiler-version 0.8.28 --watch
```
