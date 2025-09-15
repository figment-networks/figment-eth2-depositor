import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("FigmentEth2DepositorModule", (m) => {
  // Ethereum 2.0 deposit contract address (mainnet)
  // For testnets, you would use the appropriate testnet deposit contract address
  const depositContractAddress = m.getParameter("depositContract", "0x00000000219ab540356cBB839Cbe05303d7705Fa");

  const depositor = m.contract("FigmentEth2Depositor", [depositContractAddress]);

  return { depositor };
});
