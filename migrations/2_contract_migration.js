const FigmentEth2Depositor = artifacts.require("FigmentEth2Depositor");

module.exports = function (deployer) {
  deployer.deploy(FigmentEth2Depositor, false, "0x8c5fecdC472E27Bc447696F431E425D02dd46a8c");
};