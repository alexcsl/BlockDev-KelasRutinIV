import { ethers } from "ethers";

async function main() {
  // Replace with your deployed contract address
  const CONTRACT_ADDRESS = ethers.getAddress("0xEFaD62AF4b11BA436259d474555493D086ED030d".toLowerCase());

  // Connect to the network using the private key from env
  const provider = new ethers.JsonRpcProvider("https://rpc.sepolia-api.lisk.com");
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  // Minimal ABI for LiskGarden contract
  const abi = [{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"plantId","type":"uint256"}],"name":"PlantDied","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"plantId","type":"uint256"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"PlantHarvested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"uint256","name":"plantId","type":"uint256"}],"name":"PlantSeeded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"plantId","type":"uint256"},{"indexed":false,"internalType":"uint8","name":"newWaterLevel","type":"uint8"}],"name":"PlantWatered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"plantId","type":"uint256"},{"indexed":false,"internalType":"enum LiskGarden.GrowthStage","name":"newStage","type":"uint8"}],"name":"StageAdvanced","type":"event"},{"inputs":[],"name":"HARVEST_REWARD","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PLANT_PRICE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"STAGE_DURATION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"WATER_DEPLETION_RATE","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"WATER_DEPLETION_TIME","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"plantId","type":"uint256"}],"name":"calculateWaterLevel","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"plantId","type":"uint256"}],"name":"getPlant","outputs":[{"components":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"enum LiskGarden.GrowthStage","name":"stage","type":"uint8"},{"internalType":"uint256","name":"plantedDate","type":"uint256"},{"internalType":"uint256","name":"lastWatered","type":"uint256"},{"internalType":"uint8","name":"waterLevel","type":"uint8"},{"internalType":"bool","name":"exists","type":"bool"},{"internalType":"bool","name":"isDead","type":"bool"}],"internalType":"struct LiskGarden.Plant","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"getUserPlants","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"plantId","type":"uint256"}],"name":"harvestPlant","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"ownerPlants","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"plantCounter","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"plantSeed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"plants","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"enum LiskGarden.GrowthStage","name":"stage","type":"uint8"},{"internalType":"uint256","name":"plantedDate","type":"uint256"},{"internalType":"uint256","name":"lastWatered","type":"uint256"},{"internalType":"uint8","name":"waterLevel","type":"uint8"},{"internalType":"bool","name":"exists","type":"bool"},{"internalType":"bool","name":"isDead","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"plantId","type":"uint256"}],"name":"updatePlantStage","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"plantId","type":"uint256"}],"name":"waterPlant","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}];

  // Get contract instance with read-only provider for calls, signer for writes
  const LiskGarden = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);

  console.log("LiskGarden contract:", CONTRACT_ADDRESS);
  console.log("");

  try {
    // Get plant counter
    const plantCounter = await LiskGarden.plantCounter();
    console.log("Total plants:", plantCounter.toString());

    // Plant a seed (costs 0.001 ETH)
    console.log("\n🌱 Planting a seed...");
    const plantPrice = await LiskGarden.PLANT_PRICE();
    const tx = await LiskGarden.plantSeed({ value: plantPrice });
    const receipt = await tx.wait();
    console.log("✅ Seed planted! Transaction:", receipt?.hash);

    // Get new plant ID
    const newPlantCounter = await LiskGarden.plantCounter();
    const plantId = newPlantCounter;
    console.log("Your plant ID:", plantId.toString());

    // Get plant details
    const plant = await LiskGarden.getPlant(plantId);
    console.log("\n🌿 Plant details:");
    console.log("  - ID:", plant[0].toString());
    console.log("  - Owner:", plant[2]);
    console.log("  - Stage:", Number(plant[1]), "(0=SEED, 1=SPROUT, 2=GROWING, 3=BLOOMING)");
    console.log("  - Water Level:", plant[3].toString());
    console.log("  - Is Alive:", !plant[7]);
  } catch (error) {
    console.error("Error:", error);
    throw error;
  }

  // Get new plant ID
  const newPlantCounter = await LiskGarden.plantCounter();
  const plantId = newPlantCounter;
  console.log("Your plant ID:", plantId.toString());

  // Get plant details
  const plant = await LiskGarden.getPlant(plantId);
  console.log("\n🌿 Plant details:");
  console.log("  - ID:", plant.id.toString());
  console.log("  - Owner:", plant.owner);
  console.log("  - Stage:", plant.stage, "(0=SEED, 1=SPROUT, 2=GROWING, 3=BLOOMING)");
  console.log("  - Water Level:", plant.waterLevel.toString());
  console.log("  - Is Alive:", plant.isAlive);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });