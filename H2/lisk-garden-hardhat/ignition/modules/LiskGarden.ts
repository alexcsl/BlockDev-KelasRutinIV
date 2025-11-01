import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LiskGardenModule = buildModule("LiskGardenModule", (m) => {
  // Deploy LiskGarden contract
  const liskGarden = m.contract("LiskGarden");

  return { liskGarden };
});

export default LiskGardenModule;