import assert from "node:assert/strict";
import { describe, it, beforeEach } from "node:test";
import { network } from "hardhat";
import { getAddress, parseEther } from "viem";

describe("GardenToken", async () => {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  let gardenToken: any;
  let owner: any;
  let gameContract: any;
  let user1: any;
  let user2: any;

  beforeEach(async () => {
    // Get wallet signers from hardhat
    const [signerOwner, signerGameContract, signerUser1, signerUser2] = await viem.getWalletClients();
    owner = signerOwner;
    gameContract = signerGameContract;
    user1 = signerUser1;
    user2 = signerUser2;

    // Deploy GardenToken contract
    gardenToken = await viem.deployContract("GardenToken", [parseEther("1000000")]);
    
    // Set game contract
    await gardenToken.write.setGameContract([gameContract.account.address], { account: owner.account });
  });

  it("Should set the right owner", async () => {
    const contractOwner = await gardenToken.read.owner();
    assert.equal(getAddress(contractOwner), getAddress(owner.account.address));
  });

  it("Should assign initial total supply to owner", async () => {
    const ownerBalance = await gardenToken.read.balanceOf([owner.account.address]);
    const totalSupply = await gardenToken.read.totalSupply();
    assert.equal(ownerBalance, totalSupply);
  });

  it("Should have correct name, symbol and decimals", async () => {
    const name = await gardenToken.read.name();
    const symbol = await gardenToken.read.symbol();
    const decimals = await gardenToken.read.decimals();
    
    assert.equal(name, "Garden Token");
    assert.equal(symbol, "GDN");
    assert.equal(Number(decimals), 18);
  });

  it("Should calculate correct rewards for different rarities", async () => {
    // Common (rarity 1)
    const reward1 = await gardenToken.read.calculateReward([1, 3]);
    assert.equal(reward1, parseEther("10"));
    
    // Rare (rarity 2)
    const reward2 = await gardenToken.read.calculateReward([2, 3]);
    assert.equal(reward2, parseEther("20"));
    
    // Epic (rarity 3)
    const reward3 = await gardenToken.read.calculateReward([3, 3]);
    assert.equal(reward3, parseEther("30"));
    
    // Legendary (rarity 4)
    const reward4 = await gardenToken.read.calculateReward([4, 3]);
    assert.equal(reward4, parseEther("50"));
    
    // Mythic (rarity 5)
    const reward5 = await gardenToken.read.calculateReward([5, 3]);
    assert.equal(reward5, parseEther("100"));
  });

  it("Should calculate correct rewards for different growth stages", async () => {
    // Seed stage (0) - no reward
    const reward0 = await gardenToken.read.calculateReward([1, 0]);
    assert.equal(reward0, 0n);
    
    // Sprout stage (1) - 0.5x
    const reward1 = await gardenToken.read.calculateReward([1, 1]);
    assert.equal(reward1, parseEther("5"));
    
    // Growing stage (2) - 0.75x
    const reward2 = await gardenToken.read.calculateReward([1, 2]);
    assert.equal(reward2, parseEther("7.5"));
    
    // Mature stage (3) - 1x
    const reward3 = await gardenToken.read.calculateReward([1, 3]);
    assert.equal(reward3, parseEther("10"));
  });

  it("Should allow game contract to mint rewards", async () => {
    const amount = parseEther("100");
    
    await gardenToken.write.mintReward([user1.account.address, amount], { account: gameContract.account });
    
    const user1Balance = await gardenToken.read.balanceOf([user1.account.address]);
    const totalSupply = await gardenToken.read.totalSupply();
    
    assert.equal(user1Balance, amount);
    assert.equal(totalSupply, parseEther("1000100"));
  });

  it("Should enforce max supply limit", async () => {
    const maxSupply = await gardenToken.read.MAX_SUPPLY();
    const currentSupply = await gardenToken.read.totalSupply();
    const excessAmount = BigInt(maxSupply) - BigInt(currentSupply) + parseEther("1");
    
    await assert.rejects(
      gardenToken.write.mintReward([user1.account.address, excessAmount], { account: gameContract.account }),
      /Exceeds max supply/
    );
  });

  it("Should enforce daily mint limit", async () => {
    const dailyLimit = await gardenToken.read.MAX_DAILY_MINT();
    const excessAmount = BigInt(dailyLimit) + parseEther("1");
    
    await assert.rejects(
      gardenToken.write.mintReward([user1.account.address, excessAmount], { account: gameContract.account }),
      /Exceeds daily mint limit/
    );
  });

  it("Should only allow game contract to mint", async () => {
    await assert.rejects(
      gardenToken.write.mintReward([user2.account.address, parseEther("100")], { account: user1.account }),
      /Only game contract/
    );
  });

  it("Should allow users to burn tokens", async () => {
    // Give user1 some tokens
    await gardenToken.write.transfer([user1.account.address, parseEther("1000")], { account: owner.account });
    
    const burnAmount = parseEther("100");
    const initialBalance = await gardenToken.read.balanceOf([user1.account.address]);
    const initialSupply = await gardenToken.read.totalSupply();
    
    await gardenToken.write.burn([burnAmount], { account: user1.account });
    
    const newBalance = await gardenToken.read.balanceOf([user1.account.address]);
    const newSupply = await gardenToken.read.totalSupply();
    const totalBurned = await gardenToken.read.totalBurned();
    
    assert.equal(newBalance, initialBalance - burnAmount);
    assert.equal(newSupply, initialSupply - burnAmount);
    assert.equal(totalBurned, burnAmount);
  });

  it("Should enforce minimum burn amount", async () => {
    await gardenToken.write.transfer([user1.account.address, parseEther("1000")], { account: owner.account });
    
    const lessThanMin = parseEther("5");
    
    await assert.rejects(
      gardenToken.write.burn([lessThanMin], { account: user1.account }),
      /Minimum burn amount is 10 GDN/
    );
  });

  it("Should enforce burn cooldown", async () => {
    await gardenToken.write.transfer([user1.account.address, parseEther("1000")], { account: owner.account });
    
    const burnAmount = parseEther("10");
    
    await gardenToken.write.burn([burnAmount], { account: user1.account });
    
    await assert.rejects(
      gardenToken.write.burn([burnAmount], { account: user1.account }),
      /Burn cooldown active/
    );
  });

  it("Should return correct circulating supply", async () => {
    const totalSupply = await gardenToken.read.totalSupply();
    const circulatingSupply = await gardenToken.read.circulatingSupply();
    
    // Circulating supply should be less than or equal to total supply
    assert(circulatingSupply <= totalSupply, "Circulating supply should not exceed total supply");
    
    // Since no tokens are held by the contract initially, they should be equal
    assert.equal(circulatingSupply, totalSupply);
  });

  it("Should calculate burn rate correctly", async () => {
    // Burn some tokens to test calculation
    await gardenToken.write.transfer([user1.account.address, parseEther("1000")], { account: owner.account });
    await gardenToken.write.burn([parseEther("100")], { account: user1.account });
    
    const burnRate = await gardenToken.read.burnRate();
    assert(burnRate > 0n, "Burn rate should be greater than 0");
  });
});
