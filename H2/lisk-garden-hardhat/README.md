# LiskGarden - Token Ecosystem 🌱

## Overview

LiskGarden is a complete blockchain-based farming game built on Lisk Sepolia testnet. Players can plant seeds, grow plants through multiple stages, harvest rewards in GDN tokens, and use various game items to boost their farming efficiency. The project implements a full token ecosystem using ERC-20, ERC-721, and ERC-1155 standards.

**Key Features:**
- 🌱 Plant NFTs with 5 rarity tiers (Common to Mythic)
- 💰 GDN token rewards based on rarity and growth stage
- 🎮 Game items with growth multipliers and timed boosts
- 🏆 Achievement system with 5 unlockable achievements
- 📊 Complete game statistics and leaderboard tracking

## Deployed Contracts

### GardenToken (ERC-20)
- **Address:** `0x085881d03F7B5B5E686FC23F1B873204c7b1BCC3`
- **Blockscout:** https://sepolia-blockscout.lisk.com/address/0x085881d03F7B5B5E686FC23F1B873204c7b1BCC3
- **Features:**
  - Max Supply: 100 million GDN
  - Daily Mint Limit: 10,000 GDN
  - Burn Mechanism: 10 GDN minimum, 1-day cooldown
  - Reward Calculation: Dynamic based on plant rarity (1x-10x) and growth stage (0x-1x)
  - Supply Analytics: Circulating supply and burn rate tracking

### PlantNFT (ERC-721)
- **Address:** `0x9615ff6c26124F9309dDaD2Ad26C260b81836680`
- **Blockscout:** https://sepolia-blockscout.lisk.com/address/0x9615ff6c26124F9309dDaD2Ad26C260b81836680
- **Features:**
  - Mint Cost: 0.001 ETH
  - Rarity Distribution: Common (60%), Rare (25%), Epic (10%), Legendary (4%), Mythic (1%)
  - Growth Mechanics: 4 stages (Seed → Sprout → Growing → Mature)
  - Growth Requirements: 1 day + 3 waterings per stage
  - Water Cooldown: 8 hours between waterings
  - Harvest Cooldown: 1 day between harvests
  - Item Integration: Use game items to boost growth

### GameItems (ERC-1155)
- **Address:** `0x8622Ba73150220Ab9F3A0ed431465df6d69999fb`
- **Blockscout:** https://sepolia-blockscout.lisk.com/address/0x8622Ba73150220Ab9F3A0ed431465df6d69999fb
- **Features:**
  - 10 Different Items: Seeds, fertilizers, tools, and boosts
  - Item Effects: Growth multipliers (1x-10x), rarity boosts (10%-50%)
  - Timed Boosts: 1-hour and 24-hour growth accelerators
  - Consumable vs Non-Consumable: Some items burn on use, others are permanent
  - Usage Analytics: Track most used items and player statistics
  - Limited Supply Items: Golden Shovel (1000), Rainbow Watering Can (500), Mystical Fertilizer (100)

**Item Catalog:**
| ID | Item | Price | Effect | Type |
|----|------|-------|--------|------|
| 0 | Seed | 0.0001 ETH | Required for planting | Consumable |
| 1 | Fertilizer | 0.0002 ETH | 2x growth | Consumable |
| 2 | Water Can | 0.0003 ETH | Skip water cooldown | Consumable |
| 3 | Pesticide | 0.0002 ETH | 1.5x growth | Consumable |
| 10 | Golden Shovel | 0.01 ETH | 2x growth, 10% rarity | Non-Consumable |
| 11 | Rainbow Watering Can | 0.02 ETH | 3x growth, 15% rarity | Non-Consumable |
| 12 | Mystical Fertilizer | 0.05 ETH | 10x growth, 50% rarity | Consumable |
| 20 | Growth Boost 1H | 0.001 ETH | 3x growth for 1 hour | Consumable |
| 21 | Growth Boost 24H | 0.005 ETH | 5x growth for 24 hours | Consumable |
| 22 | Rare Seed Boost | 0.003 ETH | 20% rarity boost | Consumable |

### LiskGarden (Main Game Contract)
- **Address:** `0xEFaD62AF4b11BA436259d474555493D086ED030d`
- **Blockscout:** https://sepolia-blockscout.lisk.com/address/0xEFaD62AF4b11BA436259d474555493D086ED030d
- **Features:**
  - Unified Game Interface: Orchestrates all token contracts
  - Plant → Water → Grow → Harvest Flow
  - Achievement System: 5 achievements (First Plant, Tenth Plant, Hundredth Plant, First Legendary, Master Farmer)
  - Leaderboard: Track top farmers by total harvested
  - Game Statistics: Total plants minted, harvests, GDN minted
  - Batch Operations: Harvest all mature plants in one transaction

## Setup & Testing

### Installation

```bash
# Clone repository
git clone <your-repo-url>
cd lisk-garden-hardhat

# Install dependencies
npm install
```

### Environment Setup

Create `.env` file:
```env
PRIVATE_KEY=your_private_key_here
```

### Compile Contracts

```bash
npx hardhat compile
```

### Testing

```bash
# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/Contracts.test.ts

# Note: Tests use Hardhat 3 Beta with viem
# For manual testing, use Hardhat console:
npx hardhat console --network hardhat
```

### Test Coverage

The project includes comprehensive tests covering:
- ✅ GardenToken: 10+ tests (reward calculation, supply management, burn mechanics)
- ✅ PlantNFT: 15+ tests (minting, rarity, growth, harvest)
- ✅ GameItems: 15+ tests (item purchase, usage, boosts)
- ✅ LiskGarden: 20+ tests (full game integration)

## Deployment

### Deploy Individual Contracts

```bash
# Deploy GardenToken
npx hardhat ignition deploy ignition/modules/GardenToken.ts --network lisk-sepolia

# Deploy PlantNFT
npx hardhat ignition deploy ignition/modules/PlantNFT.ts --network lisk-sepolia

# Deploy GameItems
npx hardhat ignition deploy ignition/modules/GameItems.ts --network lisk-sepolia
```

### Deploy Complete Ecosystem (Recommended)

```bash
# Deploy all contracts with proper setup
npx hardhat ignition deploy ignition/modules/LiskGardenComplete.ts --network lisk-sepolia
```

This will:
1. Deploy GardenToken with 1M initial supply
2. Deploy PlantNFT
3. Deploy GameItems
4. Deploy LiskGarden
5. Configure all contract connections automatically

### Verify Contracts

```bash
npx hardhat verify --network lisk-sepolia <CONTRACT_ADDRESS>
```

## Game Flow

### 1. Buy Items 🛒

First, purchase a SEED item from GameItems contract:

```solidity
// Buy 1 SEED for 0.0001 ETH
gameItems.buyItem(0, 1, { value: 0.0001 ether });
```

### 2. Plant Seed 🌱

Use LiskGarden to plant your seed:

```solidity
// Plant seed (requires 1 SEED + 0.001 ETH)
liskGarden.plantSeed("My Rose", "Red Rose", { value: 0.001 ether });
// Returns: plantId (e.g., 0)
```

Your plant starts at **Stage 0 (Seed)** with a random rarity (1-5).

### 3. Water Plant 💧

Water your plant every 8 hours (3 times per stage):

```solidity
// Option 1: Water normally (8-hour cooldown)
plantNFT.waterPlant(plantId);

// Option 2: Use Water Can to skip cooldown
liskGarden.waterPlant(plantId); // Burns 1 WATER_CAN if you have it
```

### 4. Grow Plant 🌿

After 1 day + 3 waterings, grow to next stage:

```solidity
// Check if plant can grow
bool canGrow = plantNFT.canGrow(plantId);

// Grow plant
plantNFT.growPlant(plantId);
// Stage 0 → 1 → 2 → 3 (Mature)
```

### 5. Use Items (Optional) ⚡

Boost your plant's growth:

```solidity
// Use Fertilizer for 2x growth
liskGarden.useFertilizer(plantId);

// Use Growth Boost for timed acceleration
gameItems.useItem(plantId, 20); // 3x growth for 1 hour
```

### 6. Harvest Rewards 🎁

Once plant reaches **Stage 3 (Mature)**, harvest GDN tokens:

```solidity
// Harvest single plant
liskGarden.harvestPlant(plantId);

// Or harvest all mature plants
liskGarden.harvestAll();
```

**Reward Formula:**
```
Base Reward = 10 GDN
Rarity Multiplier: Common(1x), Rare(2x), Epic(3x), Legendary(5x), Mythic(10x)
Stage Multiplier: Seed(0x), Sprout(0.5x), Growing(0.75x), Mature(1x)

Final Reward = Base × Rarity × Stage
Example: Mythic Mature = 10 × 10 × 1 = 100 GDN
```

### 7. Unlock Achievements 🏆

Achievements unlock automatically:
- 🌱 **First Plant**: Plant 1 seed
- 🌿 **Tenth Plant**: Plant 10 seeds
- 🌳 **Hundredth Plant**: Plant 100 seeds
- ⭐ **First Legendary**: Get a Legendary or Mythic plant
- 👑 **Master Farmer**: Harvest 10,000 GDN total

## Game Economics

### Token Supply
- **Max Supply:** 100,000,000 GDN
- **Daily Mint Limit:** 10,000 GDN
- **Initial Supply:** 1,000,000 GDN (to owner)

### Costs
- **Plant Seed:** 0.001 ETH + 1 SEED item
- **Items:** 0.0001 - 0.05 ETH (see Item Catalog)

### Rewards
- **Common Mature:** 10 GDN
- **Rare Mature:** 20 GDN
- **Epic Mature:** 30 GDN
- **Legendary Mature:** 50 GDN
- **Mythic Mature:** 100 GDN

### Cooldowns
- **Water:** 8 hours
- **Growth:** 1 day per stage
- **Harvest:** 1 day
- **Burn:** 1 day

## Architecture

```
LiskGarden (Main Game)
    ├── GardenToken (ERC-20)
    │   ├── Reward minting
    │   ├── Supply management
    │   └── Burn mechanics
    │
    ├── PlantNFT (ERC-721)
    │   ├── Plant minting
    │   ├── Growth tracking
    │   └── Harvest logic
    │
    └── GameItems (ERC-1155)
        ├── Item sales
        ├── Boost tracking
        └── Usage analytics
```

## Smart Contract Interactions

### For Players

```javascript
// 1. Buy SEED
await gameItems.buyItem(0, 1, { value: parseEther("0.0001") });

// 2. Plant
await liskGarden.plantSeed("Rose", "Red Rose", { value: parseEther("0.001") });

// 3. Water (repeat 3x per stage)
await plantNFT.waterPlant(0);

// 4. Grow (after 1 day + 3 waterings)
await plantNFT.growPlant(0);

// 5. Harvest (when mature)
await liskGarden.harvestPlant(0);
```

### For Developers

```javascript
// Get plant details
const plant = await plantNFT.getPlant(plantId);
console.log(plant.rarity, plant.growthStage);

// Check if can grow
const canGrow = await plantNFT.canGrow(plantId);

// Get active boosts
const boosts = await gameItems.getActiveBoosts(playerAddress, plantId);

// Get game statistics
const stats = await liskGarden.getGameStats();
console.log(stats); // [totalPlants, totalHarvests, totalGDN, totalItems]
```

## Project Structure

```
lisk-garden-hardhat/
├── contracts/
│   ├── GardenToken.sol       # ERC-20 reward token
│   ├── PlantNFT.sol          # ERC-721 plant NFTs
│   ├── GameItems.sol         # ERC-1155 game items
│   └── LiskGarden.sol        # Main game contract
├── ignition/modules/
│   ├── GardenToken.ts
│   ├── PlantNFT.ts
│   ├── GameItems.ts
│   └── LiskGardenComplete.ts # Deploy all
├── test/
│   └── Contracts.test.ts     # Comprehensive tests
├── CHECKLIST.md              # Feature checklist
├── TESTING.md                # Testing guide
└── README.md                 # This file
```

## Technologies Used

- **Solidity ^0.8.30** - Smart contract language
- **Hardhat 3 Beta** - Development environment
- **Viem** - Ethereum library
- **OpenZeppelin Contracts** - Secure token standards
- **TypeScript** - Type-safe scripting
- **Lisk Sepolia** - Testnet deployment

## Security Features

- ✅ OpenZeppelin battle-tested contracts
- ✅ Owner-only admin functions
- ✅ Pausable token transfers
- ✅ Supply caps and limits
- ✅ Cooldown mechanisms
- ✅ Input validation
- ✅ Reentrancy protection (via OpenZeppelin)

## Future Enhancements

- [ ] Frontend dApp with React
- [ ] Marketplace for trading plants
- [ ] Breeding system for new plant varieties
- [ ] Seasonal events with special rewards
- [ ] Guild/team features
- [ ] Mobile app integration
- [ ] Cross-chain bridge to Lisk mainnet

## License

MIT License - see LICENSE file for details

## Author

Built for BlockDev Kelas Rutin IV - Homework 2

## Links

- **Lisk Sepolia Faucet:** https://sepolia-faucet.lisk.com/
- **Lisk Docs:** https://docs.lisk.com/
- **Blockscout Explorer:** https://sepolia-blockscout.lisk.com/

---

**Happy Farming! 🌱🎮**
