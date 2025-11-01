import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "ethers";

const LiskGardenCompleteModule = buildModule("LiskGardenCompleteModule", (m) => {
  const initialSupply = m.getParameter("initialSupply", parseEther("1000000"));
  
  const gardenToken = m.contract("GardenToken", [initialSupply]);
  const plantNFT = m.contract("PlantNFT");
  const gameItems = m.contract("GameItems");
  
  const liskGarden = m.contract("LiskGarden", [gardenToken, plantNFT, gameItems]);
  
  m.call(gardenToken, "setGameContract", [plantNFT]);
  m.call(plantNFT, "setGardenToken", [gardenToken]);
  m.call(plantNFT, "setGameItems", [gameItems]);
  m.call(plantNFT, "setGameContract", [liskGarden]);
  m.call(gameItems, "setPlantNFT", [plantNFT]);

  return { gardenToken, plantNFT, gameItems, liskGarden };
});

export default LiskGardenCompleteModule;
