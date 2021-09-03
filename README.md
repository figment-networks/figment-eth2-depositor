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
4. Set a working version of the compiler `npx truffle obtain --solc 0.8.1`

Test on your local blockchain
------------

1. Clone the repository
2. Install the npm dependencies.
3. Install [Ganache](https://www.trufflesuite.com/ganache) and [Truffle](https://www.trufflesuite.com/truffle)
4. Set an working version of the compiler `npx truffle obtain --solc 0.8.1`
5. Run ganache and quick start an empty workspace
6. Tun `npx truffle deploy` to compile & deploy.

Deployment (Goerli)
------------

Smart contracts should be deployed with such constructor parameters:

1. create a `secrets.json` file with **mnemonic** and infura **projectId**
2. deploy the contract `npx truffle migrate --network goerli`

```
....

2_contract_migration.js
=======================

   Deploying 'FigmentEth2Depositor'
   --------------------------------
   > transaction hash:    0x2213b23bd3853dd7a1c6a8b3407baf1eeed84e28cba10cfbbf986f689c1ef5aa
   > Blocks: 2            Seconds: 24
   > contract address:    0x35D6EC221C799f29ACC2B7246ef1CCb0d4334ab5

...
```

3. At the end of deployment save the **contract address**
4. Consult the contract on explorer: `https://goerli.etherscan.io/address/<CONTRACT_ADDRESS>`



```
https://goerli.etherscan.io/address/0x35D6EC221C799f29ACC2B7246ef1CCb0d4334ab5
```

> Deployment fees: **0.001361887011080639**

How to Use
------------

1. Choose amount of Eth2 validator nodes you want to create.
2. Create array with your pubkeys, withdrawal_credentials, signatures and calldata deposit_data_roots.
3. Use _deposit()_ function on `FigmentEth2Depositor` with required ETH value to make deposits to Eth2 Deposit Contract.

License
=========

MIT
