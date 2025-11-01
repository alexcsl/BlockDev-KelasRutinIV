import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const GameItemsModule = buildModule("GameItemsModule", (m) => {
  const gameItems = m.contract("GameItems");

  return { gameItems };
});

export default GameItemsModule;
