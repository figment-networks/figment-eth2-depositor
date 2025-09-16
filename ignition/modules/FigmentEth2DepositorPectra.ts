import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("FigmentEth2DepositorPectraModule", (m) => {
  // Ethereum 2.0 deposit contract address (mainnet)
  // This is also the same address on hoodi testnet
  const depositContractAddress = m.getParameter("depositContract", "0x00000000219ab540356cBB839Cbe05303d7705Fa");

  const depositor = m.contract("FigmentEth2DepositorPectra", [depositContractAddress]);

  return { depositor };
});
