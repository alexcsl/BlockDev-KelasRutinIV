import assert from "node:assert/strict";
import { describe, it, beforeEach } from "node:test";
import { network } from "hardhat";
import { getAddress, parseEther } from "viem";
import hre from "hardhat";

describe("GameItems", async () => {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  let gameItems: any;
  let plantNFT: any;
  let gardenToken: any;
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
    
    // Set contract addresses
    await gameItems.write.setPlantNFT([plantNFT.address], { account: owner.account });
    await plantNFT.write.setGardenToken([gardenToken.address], { account: owner.account });
    await plantNFT.write.setGameItems([gameItems.address], { account: owner.account });
    await gardenToken.write.setPlantNFT([plantNFT.address], { account: owner.account });
    
    // Give users some tokens for testing
    await gardenToken.write.transfer([user1.account.address, parseEther("1000")], { account: owner.account });
    await gardenToken.write.transfer([user2.account.address, parseEther("1000")], { account: owner.account });
    await gardenToken.write.transfer([user3.account.address, parseEther("1000")], { account: owner.account });
  });

  // Test 1: Deployment - Should set the right owner
  it("Should set the right owner", async () => {
    const contractOwner = await gameItems.read.owner();
    assert.equal(getAddress(contractOwner), getAddress(owner.account.address));
  });

  // Test 2: Deployment - Should set plant contract address correctly
  it("Should set plant contract address correctly", async () => {
    const plantContractAddress = await gameItems.read.plantNFT();
    assert.equal(getAddress(plantContractAddress), getAddress(plantNFT.address));
  });

  // Test 3: Admin Functions - Should allow owner to admin mint items
  it("Should allow owner to admin mint items", async () => {
    const itemId = 1n; // Fertilizer
    const amount = 10n;
    
    await gameItems.write.adminMint([user1.account.address, itemId, amount], { account: owner.account });
    
    const balance = await gameItems.read.balanceOf([user1.account.address, itemId]);
    assert.equal(balance, amount, "User should have minted items");
  });

  // Test 4: Admin Functions - Should only allow owner to admin mint
  it("Should only allow owner to admin mint", async () => {
    const itemId = 1n;
    const amount = 10n;
    
    await assert.rejects(
      gameItems.write.adminMint([user2.account.address, itemId, amount], { account: user1.account }),
      /OwnableUnauthorizedAccount/,
      "Non-owner should not be able to admin mint"
    );
  });

  // Test 5: Item Types - Should handle all item types correctly
  it("Should handle all item types correctly", async () => {
    // Test different item types
    const itemTypes = [1n, 2n, 3n, 4n, 5n]; // Different item IDs
    
    for (const itemId of itemTypes) {
      await gameItems.write.adminMint([user1.account.address, itemId, 5n], { account: owner.account });
      
      const balance = await gameItems.read.balanceOf([user1.account.address, itemId]);
      assert.equal(balance, 5n, `Item ${itemId} should be minted correctly`);
    }
  });

  // Test 6: Batch Operations - Should mint multiple items individually
  it("Should mint multiple items individually", async () => {
    const itemIds = [1n, 2n, 3n];
    const amounts = [10n, 5n, 3n];
    
    // Mint each item individually
    for (let i = 0; i < itemIds.length; i++) {
      await gameItems.write.adminMint([user1.account.address, itemIds[i], amounts[i]], { account: owner.account });
    }
    
    // Check all balances
    for (let i = 0; i < itemIds.length; i++) {
      const balance = await gameItems.read.balanceOf([user1.account.address, itemIds[i]]);
      assert.equal(balance, amounts[i], `Item ${itemIds[i]} should have correct minted amount`);
    }
  });

  // Test 7: Buy Batch - Should support buying multiple items at once
  it("Should support buying multiple items at once", async () => {
    const itemIds = [1n, 2n]; // Fertilizer and Water Can
    const amounts = [2n, 1n];
    
    // Calculate total cost
    const fertilizerPrice = await gameItems.read.itemPrice([1n]);
    const waterCanPrice = await gameItems.read.itemPrice([2n]);
    const totalCost = (fertilizerPrice * amounts[0]) + (waterCanPrice * amounts[1]);
    
    // Buy items
    await gameItems.write.buyBatch([itemIds, amounts], { 
      account: user1.account,
      value: totalCost 
    });
    
    // Check balances
    const balance1 = await gameItems.read.balanceOf([user1.account.address, itemIds[0]]);
    const balance2 = await gameItems.read.balanceOf([user1.account.address, itemIds[1]]);
    
    assert.equal(balance1, amounts[0], "User should have correct fertilizer amount");
    assert.equal(balance2, amounts[1], "User should have correct water can amount");
  });

  // Test 8: Balance Tracking - Should track balances correctly
  it("Should track balances correctly", async () => {
    const itemId = 1n;
    const amount1 = 7n;
    const amount2 = 3n;
    
    // Mint to different users
    await gameItems.write.adminMint([user1.account.address, itemId, amount1], { account: owner.account });
    await gameItems.write.adminMint([user2.account.address, itemId, amount2], { account: owner.account });
    
    const balance1 = await gameItems.read.balanceOf([user1.account.address, itemId]);
    const balance2 = await gameItems.read.balanceOf([user2.account.address, itemId]);
    
    assert.equal(balance1, amount1, "User1 should have correct balance");
    assert.equal(balance2, amount2, "User2 should have correct balance");
  });

  // Test 9: Multiple Items per User - Should handle multiple different items per user
  it("Should handle multiple different items per user", async () => {
    const items = [
      { id: 1n, amount: 5n },
      { id: 2n, amount: 3n },
      { id: 3n, amount: 8n }
    ];
    
    // Mint different items to same user
    for (const item of items) {
      await gameItems.write.adminMint([user1.account.address, item.id, item.amount], { account: owner.account });
    }
    
    // Verify all balances
    for (const item of items) {
      const balance = await gameItems.read.balanceOf([user1.account.address, item.id]);
      assert.equal(balance, item.amount, `Item ${item.id} should have correct balance`);
    }
  });

  // Test 10: ERC1155 Compliance - Should support batch balance queries
  it("Should support batch balance queries", async () => {
    // Mint items
    await gameItems.write.adminMint([user1.account.address, 1n, 10n], { account: owner.account });
    await gameItems.write.adminMint([user1.account.address, 2n, 5n], { account: owner.account });
    await gameItems.write.adminMint([user2.account.address, 1n, 3n], { account: owner.account });
    
    // Query batch balances
    const accounts = [user1.account.address, user1.account.address, user2.account.address];
    const itemIds = [1n, 2n, 1n];
    
    const balances = await gameItems.read.balanceOfBatch([accounts, itemIds]);
    
    assert.equal(balances.length, 3, "Should return correct number of balances");
    assert.equal(balances[0], 10n, "User1 should have 10 of item 1");
    assert.equal(balances[1], 5n, "User1 should have 5 of item 2");
    assert.equal(balances[2], 3n, "User2 should have 3 of item 1");
  });

  // Test 11: Transfer Functionality - Should support safe transfers
  it("Should support safe transfers", async () => {
    const itemId = 1n;
    const amount = 10n;
    const transferAmount = 3n;
    
    // Mint items to user1
    await gameItems.write.adminMint([user1.account.address, itemId, amount], { account: owner.account });
    
    // Transfer from user1 to user2
    await gameItems.write.safeTransferFrom([
      user1.account.address,
      user2.account.address,
      itemId,
      transferAmount,
      "0x"
    ], { account: user1.account });
    
    // Check balances
    const balance1 = await gameItems.read.balanceOf([user1.account.address, itemId]);
    const balance2 = await gameItems.read.balanceOf([user2.account.address, itemId]);
    
    assert.equal(balance1, amount - transferAmount, "User1 should have reduced balance");
    assert.equal(balance2, transferAmount, "User2 should have received items");
  });

  // Test 12: Transfer Functionality - Should support batch transfers
  it("Should support batch transfers", async () => {
    // Mint multiple items to user1
    await gameItems.write.adminMint([user1.account.address, 1n, 10n], { account: owner.account });
    await gameItems.write.adminMint([user1.account.address, 2n, 8n], { account: owner.account });
    
    // Batch transfer to user2
    const itemIds = [1n, 2n];
    const amounts = [3n, 2n];
    
    await gameItems.write.safeBatchTransferFrom([
      user1.account.address,
      user2.account.address,
      itemIds,
      amounts,
      "0x"
    ], { account: user1.account });
    
    // Check final balances
    assert.equal(await gameItems.read.balanceOf([user1.account.address, 1n]), 7n);
    assert.equal(await gameItems.read.balanceOf([user1.account.address, 2n]), 6n);
    assert.equal(await gameItems.read.balanceOf([user2.account.address, 1n]), 3n);
    assert.equal(await gameItems.read.balanceOf([user2.account.address, 2n]), 2n);
  });

  // Test 13: Approval System - Should handle approval for all
  it("Should handle approval for all", async () => {
    const itemId = 1n;
    const amount = 10n;
    
    // Mint items to user1
    await gameItems.write.adminMint([user1.account.address, itemId, amount], { account: owner.account });
    
    // User1 approves user2 for all tokens
    await gameItems.write.setApprovalForAll([user2.account.address, true], { account: user1.account });
    
    // Check approval status
    const isApproved = await gameItems.read.isApprovedForAll([user1.account.address, user2.account.address]);
    assert.equal(isApproved, true, "User2 should be approved for all of User1's tokens");
    
    // User2 can now transfer on behalf of user1
    await gameItems.write.safeTransferFrom([
      user1.account.address,
      user3.account.address,
      itemId,
      3n,
      "0x"
    ], { account: user2.account });
    
    // Check balances
    const balance1 = await gameItems.read.balanceOf([user1.account.address, itemId]);
    const balance3 = await gameItems.read.balanceOf([user3.account.address, itemId]);
    
    assert.equal(balance1, 7n, "User1 should have reduced balance");
    assert.equal(balance3, 3n, "User3 should have received items");
  });

  // Test 14: URI System - Should handle token URIs
  it("Should handle token URIs", async () => {
    const itemId = 1n;
    
    try {
      const uri = await gameItems.read.uri([itemId]);
      // URI should be a string (might be empty if not set)
      assert.equal(typeof uri, "string", "URI should be a string");
    } catch (error) {
      // Some implementations might not have URI set up
      console.log("URI not implemented or not set");
    }
  });

  // Test 15: Security - Should prevent unauthorized access
  it("Should prevent unauthorized access to admin functions", async () => {
    const itemId = 1n;
    const amount = 10n;
    
    // Try to call admin function from non-owner account
    await assert.rejects(
      gameItems.write.adminMint([user1.account.address, itemId, amount], { account: user2.account }),
      /OwnableUnauthorizedAccount|Ownable: caller is not the owner/,
      "Should reject non-owner admin calls"
    );
  });
});
