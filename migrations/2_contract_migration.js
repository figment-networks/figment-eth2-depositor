const FigmentEth2Depositor = artifacts.require("FigmentEth2Depositor");

module.exports = function (deployer) {
  // Contract address on mainnet: 0x00000000219ab540356cBB839Cbe05303d7705Fa
  // Contract address on testnet: 0x8c5fecdC472E27Bc447696F431E425D02dd46a8c 
  deployer.deploy(FigmentEth2Depositor, "0x8c5fecdC472E27Bc447696F431E425D02dd46a8c");
};