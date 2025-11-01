import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "ethers";

const GardenTokenModule = buildModule("GardenTokenModule", (m) => {
  const initialSupply = m.getParameter("initialSupply", parseEther("1000000"));
  
  const gardenToken = m.contract("GardenToken", [initialSupply]);

  return { gardenToken };
});

export default GardenTokenModule;
