import assert from "node:assert/strict";
import { describe, it, beforeEach } from "node:test";
import { network } from "hardhat";
import { getAddress, parseEther } from "viem";
import hre from "hardhat";

describe("LiskGarden", async () => {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  let liskGarden: any;
  let gardenToken: any;
  let plantNFT: any;
  let gameItems: any;
  let owner: any;
  let user1: any;
  let user2: any;
  let user3: any;

  beforeEach(async () => {
    // Get wallet signers from hardhat
    const [signerOwner, signerUser1, signerUser2, signerUser3] = await viem.getWalletClients();
    owner = signerOwner;
    user1 = signerUser1;
    user2 = signerUser2;
    user3 = signerUser3;

    // Deploy GardenToken contract
    gardenToken = await viem.deployContract("GardenToken", [parseEther("1000000")]);
    
    // Deploy GameItems contract
    gameItems = await viem.deployContract("GameItems");
    
    // Deploy PlantNFT contract
    plantNFT = await viem.deployContract("PlantNFTSkeleton");
    
    // Deploy LiskGarden contract
    liskGarden = await viem.deployContract("LiskGarden", [
      gardenToken.address,
      plantNFT.address,
      gameItems.address
    ]);
    
    // Set contract addresses
    await gardenToken.write.setPlantNFT([plantNFT.address], { account: owner.account });
    await plantNFT.write.setGardenToken([gardenToken.address], { account: owner.account });
    await plantNFT.write.setGameItems([gameItems.address], { account: owner.account });
    await gameItems.write.setPlantNFT([plantNFT.address], { account: owner.account });
    
    // Give users some tokens for testing
    await gardenToken.write.transfer([user1.account.address, parseEther("1000")], { account: owner.account });
    await gardenToken.write.transfer([user2.account.address, parseEther("1000")], { account: owner.account });
    await gardenToken.write.transfer([user3.account.address, parseEther("1000")], { account: owner.account });
    
    // Give users seed items for planting
    await gameItems.write.adminMint([user1.account.address, 0n, 10n], { account: owner.account }); // SEED
    await gameItems.write.adminMint([user2.account.address, 0n, 10n], { account: owner.account }); // SEED
    await gameItems.write.adminMint([user3.account.address, 0n, 10n], { account: owner.account }); // SEED
  });

  // Test 1: Deployment - Should set the right owner
  it("Should set the right owner", async () => {
    const contractOwner = await liskGarden.read.owner();
    assert.equal(getAddress(contractOwner), getAddress(owner.account.address));
  });

  // Test 2: Deployment - Should set contract addresses correctly
  it("Should set contract addresses correctly", async () => {
    const gardenTokenAddr = await liskGarden.read.gardenToken();
    const plantNFTAddr = await liskGarden.read.plantNFT();
    const gameItemsAddr = await liskGarden.read.gameItems();
    
    assert.equal(getAddress(gardenTokenAddr), getAddress(gardenToken.address));
    assert.equal(getAddress(plantNFTAddr), getAddress(plantNFT.address));
    assert.equal(getAddress(gameItemsAddr), getAddress(gameItems.address));
  });

  // Test 3: Treasury - Should initialize treasury balance
  it("Should initialize treasury balance", async () => {
    const treasuryBalance = await liskGarden.read.treasuryBalance();
    assert.equal(treasuryBalance, 0n);
  });

  // Test 4: Integration - Should work with constituent contracts
  it("Should work with constituent contracts", async () => {
    // Test that we can check constituent contract functions
    const plantCost = await liskGarden.read.PLANT_COST();
    assert.equal(plantCost, parseEther("0.001"));
    
    // Test that GameItems has some items available
    const seedPrice = await gameItems.read.itemPrice([0n]);
    assert(seedPrice > 0n, "Seed should have a price");
    
    // Test that PlantNFT is ready - check actual name from PlantNFTSkeleton contract
    const plantName = await plantNFT.read.name();
    assert.equal(plantName, "Lisk Garden Plant");
  });

  // Test 5: Plant Operations - Should require sufficient payment
  it("Should require sufficient payment for planting", async () => {
    const plantCost = await liskGarden.read.PLANT_COST();
    const insufficientPayment = plantCost / 2n;
    
    await assert.rejects(
      liskGarden.write.plantSeed(["Rose", "Rosa"], { 
        account: user1.account,
        value: insufficientPayment
      }),
      /Insufficient payment/,
      "Should reject insufficient payment"
    );
  });

  // Test 6: Plant Operations - Should require seed item
  it("Should require seed item for planting", async () => {
    const plantCost = await liskGarden.read.PLANT_COST();
    
    // First, burn all seeds
    const seedBalance = await gameItems.read.balanceOf([user1.account.address, 0n]);
    if (seedBalance > 0n) {
      await gameItems.write.safeTransferFrom([
        user1.account.address,
        user2.account.address,
        0n,
        seedBalance,
        "0x"
      ], { account: user1.account });
    }
    
    await assert.rejects(
      liskGarden.write.plantSeed(["Rose", "Rosa"], { 
        account: user1.account,
        value: plantCost
      }),
      /No seed item/,
      "Should require seed item"
    );
  });

  // Test 7: Game Statistics - Should initialize correctly
  it("Should initialize game statistics correctly", async () => {
    const stats = await liskGarden.read.getGameStats();
    
    assert.equal(stats.totalPlantsMinted, 0n);
    assert.equal(stats.totalHarvests, 0n);
    assert.equal(stats.totalGDNMinted, 0n);
  });

  // Test 8: Player Statistics - Should return empty stats for new players
  it("Should return empty stats for new players", async () => {
    const playerStats = await liskGarden.read.getPlayerStats([user1.account.address]);
    
    assert.equal(playerStats[0], 0n); // plantsOwned
    assert.equal(playerStats[1], 0n); // totalHarvestedAmount
    assert.equal(playerStats[2], 0n); // achievementCount
  });

  // Test 9: Treasury Management - Should check withdraw behavior
  it("Should handle withdraw correctly", async () => {
    const initialTreasury = await liskGarden.read.treasuryBalance();
    assert.equal(initialTreasury, 0n);
    
    // LiskGarden contract requires balance > 0 to withdraw
    // So with empty treasury, withdraw should revert
    await assert.rejects(
      liskGarden.write.withdraw({ account: owner.account }),
      /No balance to withdraw/,
      "Should reject withdrawal of empty treasury"
    );
  });

  // Test 10: Treasury Management - Should only allow owner to withdraw
  it("Should only allow owner to withdraw treasury", async () => {
    await assert.rejects(
      liskGarden.write.withdraw({ account: user1.account }),
      /Only owner/,
      "Should reject non-owner withdrawal"
    );
  });

  // Test 11: Contract Integration - Should get contract addresses
  it("Should get contract addresses", async () => {
    const addresses = await liskGarden.read.getContractAddresses();
    
    assert.equal(getAddress(addresses[0]), getAddress(gardenToken.address)); // gardenTokenAddr
    assert.equal(getAddress(addresses[1]), getAddress(plantNFT.address)); // plantNFTAddr
    assert.equal(getAddress(addresses[2]), getAddress(gameItems.address)); // gameItemsAddr
  });

  // Test 12: Receive ETH - Should accept direct ETH payments
  it("Should accept direct ETH payments", async () => {
    const initialTreasury = await liskGarden.read.treasuryBalance();
    const donation = parseEther("0.1");
    
    // Send ETH directly to contract using wallet client
    const hash = await user1.sendTransaction({
      to: liskGarden.address,
      value: donation,
    });
    
    // Wait for transaction to be confirmed
    await publicClient.waitForTransactionReceipt({ hash });
    
    const newTreasury = await liskGarden.read.treasuryBalance();
    assert.equal(newTreasury, initialTreasury + donation);
  });

  // Test 13: Player Tracking - Should track plants owned correctly
  it("Should track plants owned correctly", async () => {
    // Check initial state
    const totalPlants = await liskGarden.read.totalPlantsMinted();
    const user1Plants = await liskGarden.read.totalPlantsOwned([user1.account.address]);
    const user2Plants = await liskGarden.read.totalPlantsOwned([user2.account.address]);
    
    assert.equal(totalPlants, 0n);
    assert.equal(user1Plants, 0n);  
    assert.equal(user2Plants, 0n);
  });

  // Test 14: Edge Cases - Should handle zero payment correctly  
  it("Should handle edge cases appropriately", async () => {
    // Try to plant with zero payment
    await assert.rejects(
      liskGarden.write.plantSeed(["Rose", "Rosa"], { 
        account: user1.account,
        value: 0n
      }),
      /Insufficient payment/,
      "Should reject zero payment"
    );
  });

  // Test 15: Game Constants - Should have correct game constants
  it("Should have correct game constants", async () => {
    const plantCost = await liskGarden.read.PLANT_COST();
    const seedItemId = await liskGarden.read.SEED_ITEM_ID();
    const waterCanItemId = await liskGarden.read.WATER_CAN_ITEM_ID();
    const fertilizerItemId = await liskGarden.read.FERTILIZER_ITEM_ID();
    
    assert.equal(plantCost, parseEther("0.001"));
    assert.equal(seedItemId, 0n);
    assert.equal(waterCanItemId, 2n);
    assert.equal(fertilizerItemId, 1n);
  });
});
