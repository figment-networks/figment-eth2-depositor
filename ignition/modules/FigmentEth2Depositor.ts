import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("FigmentEth2DepositorModule", (m) => {
  const depositor = m.contract("FigmentEth2Depositor");

  m.call(depositor, "deposit", [5n]);

  return { depositor };
});
