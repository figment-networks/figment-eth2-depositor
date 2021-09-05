Figment Finance Eth2 Depositor
=========

Figment Eth2 Depositor allows convenient way to send 1 to 100 deposits in one transaction to Eth2 Deposit Contract.

Contracts
=========

Below is a list of contracts we use for this service:

<dl>
  <dt>Ownable, Pausable</dt>
  <dd>Openzepellin smart contracts. The first contract allows for managing ownership. The second contract allows for pausing the contract and vice versa.</dd>
</dl>

<dl>
  <dt>FigmentEth2Depositor</dt>
  <dd>A smart contract that accepts up to 3200 ETH and sends up to 100 transactions with required collateral (32 ETH) to Eth2 Deposit Contract.</dd>
</dl>

Installation
------------

1. Clone the repository
2. Install the npm dependencies `npm install`
3. Set a working version of the compiler `npx truffle obtain --solc v0.8.1+commit.df193b15`

Deployment (Goerli)
------------

1. Create a `secrets.json` file with:
  * Your **mnemonic** 
  * Infura **projectId**  
  * Ether-scan **etherScanApiKey**
2. Deploy the contract `npx truffle migrate --network goerli`
3. Run `npx truffle run verify FigmentEth2Depositor --network goerli`

```text
Verifying FigmentEth2Depositor
Pass - Verified: https://goerli.etherscan.io/address/0x7F928Cd880Dff0cFbe2055B611908CEc7dBF95E8#contracts
Successfully verified 1 contract(s).
```

How to Use
------------

1. Choose amount of Eth2 validator nodes you want to create.
2. Create array with your pubkeys, withdrawal_credentials, signatures and calldata deposit_data_roots.
3. Use _deposit()_ function on `FigmentEth2Depositor` with required ETH value to make deposits to Eth2 Deposit Contract.

License
=========

MIT
