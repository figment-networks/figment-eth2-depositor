const FigmentEth2Depositor = artifacts.require("FigmentEth2Depositor");

module.exports = function (deployer) {
  deployer.deploy(FigmentEth2Depositor, false, "0x0000000000000000000000000000000000000000");
};