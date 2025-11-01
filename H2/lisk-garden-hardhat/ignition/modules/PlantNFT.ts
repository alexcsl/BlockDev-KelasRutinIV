import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PlantNFTModule = buildModule("PlantNFTModule", (m) => {
  const plantNFT = m.contract("PlantNFT");

  return { plantNFT };
});

export default PlantNFTModule;
