//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces for external contracts
interface IGardenToken {
    function mintReward(address to, uint256 amount) external;
    function mintPlantReward(address to, uint256 plantId, uint8 rarity, uint256 growthStage) external;
    function calculateReward(uint8 rarity, uint256 growthStage) external pure returns (uint256);
}

interface IGameItems {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function burn(address from, uint256 id, uint256 amount) external;
}

contract PlantNFT is ERC721, Ownable {
    uint256 private _nextTokenId;
    address public gameContract;
    
    // External contract references
    IGardenToken public gardenToken;
    IGameItems public gameItems;

    // Constants
    uint256 public constant WATER_COOLDOWN = 8 hours; // Water cooldown: 8 hours
    uint256 public constant STAGE_DURATION = 1 days; // Time: 1 day per stage
    uint256 public constant WATERINGS_PER_STAGE = 3; // Waterings: 3 waterings per stage
    uint256 public constant MINT_COST = 0.001 ether;
    uint256 public constant HARVEST_COOLDOWN = 1 days;

    // =================== PLANT METADATA ====================
    struct PlantMetaData{
        string name;
        string species;
        uint256 plantedAt;
        uint8 rarity;
        uint256 lastWatered;
        uint256 growthStage;
        uint256 waterCount;
        bool harvested;
    }

    mapping(uint256 => PlantMetaData) public plants;
    mapping(uint256 => uint256) public growthBoost; // tokenId => boost multiplier
    mapping(uint256 => uint256) public waterCount; // tokenId => water count
    mapping(uint256 => uint256) public lastGrowthTime; // tokenId => last growth timestamp
    mapping(uint256 => uint256) public lastHarvestTime; // tokenId => last harvest timestamp
    address public gameItemsContract;

    event PlantMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string species,
        uint8 rarity
    );

    event PlantWatered(uint256 indexed tokenId, uint256 timestamp);
    event PlantGrown(uint256 indexed tokenId, uint256 newStage);
    event PlantHarvested(uint256 indexed tokenId, address indexed owner, uint256 reward);
    event FertilizerUsed(uint256 indexed tokenId, uint256 itemId, uint256 boost);


    modifier onlyGameContract(){
        require(msg.sender == gameContract, "Only gameContract");
        _;
    }

    // CONSTRUCTOR

    constructor() ERC721 ("Lisk Garden Plant" , "PLANT") Ownable(msg.sender){}
    
    // Admin functions 
    function setGameContract(address _gameContract) external onlyOwner{
        require(_gameContract != address(0), "Invalid address");
        gameContract = _gameContract;
    }   

    function setGardenToken(address _gardenToken) external onlyOwner {
        require(_gardenToken != address(0), "Invalid address");
        gardenToken = IGardenToken(_gardenToken);
    }

    function setGameItems(address _gameItems) external onlyOwner {
        require(_gameItems != address(0), "Invalid address");
        gameItems = IGameItems(_gameItems);
        gameItemsContract = _gameItems;
    }

    function _calculateRarity() internal view returns (uint8) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))
        ) % 100;

        // 60% Common, 25% Rare, 10% Epic, 4% Legendary, 1% Mythic
        if (rand < 60) return 1; // Common (0-59)
        else if (rand < 85) return 2; // Rare (60-84)
        else if (rand < 95) return 3; // Epic (85-94)
        else if (rand < 99) return 4; // Legendary (95-98)
        else return 5; // Mythic (99)
    }

    /**
     * Minting cost: 0.001 ETH
     * Rarity probability:
     *   - Common (1): 60%
     *   - Rare (2): 25%
     *   - Epic (3): 10%
     *   - Legendary (4): 4%
     *   - Mythic (5): 1%
     */
    function mintPlant(string memory name, string memory species)
        external
        payable
        returns (uint256)
    {
        require(msg.value >= MINT_COST, "Insufficient payment");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(species).length > 0, "Species cannot be empty");

        uint8 rarity = _calculateRarity(); // Random with VRF or blockhash
        uint256 tokenId = _nextTokenId++;
        
        _mint(msg.sender, tokenId);

        plants[tokenId] = PlantMetaData({
            name: name,
            species: species,
            plantedAt: block.timestamp,
            rarity: rarity,
            lastWatered: block.timestamp,
            growthStage: 0,
            waterCount: 0,
            harvested: false
        });

        // Initialize mappings
        waterCount[tokenId] = 0;
        growthBoost[tokenId] = 1; // Default 1x boost

        emit PlantMinted(tokenId, msg.sender, species, rarity);

        return tokenId;
    }

    // Alternative mint function with custom parameters (admin only)
    function mintPlantCustom(address to, string memory name, string memory species, uint8 rarity) external onlyOwner returns(uint256) {
        require(to != address(0), "Invalid address");
        require(rarity >= 1 && rarity <= 5, "Invalid rarity");

        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);

        plants[tokenId] = PlantMetaData({
            name: name,
            species: species,
            plantedAt: block.timestamp,
            rarity: rarity,
            lastWatered: block.timestamp,
            growthStage: 0,
            waterCount: 0,
            harvested: false
        });

        // Initialize mappings
        waterCount[tokenId] = 0;
        growthBoost[tokenId] = 1; // Default 1x boost

        emit PlantMinted(tokenId, to, species, rarity);

        return tokenId;
    }

    /**
     * Growth requirements:
     * - Time: 1 day per stage
     * - Waterings: 3 waterings per stage
     * - Max stage: 3 (mature)
     * - Water cooldown: 8 hours
     */
    function waterPlant(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        PlantMetaData storage plant = plants[tokenId];
        require(block.timestamp >= plant.lastWatered + WATER_COOLDOWN, "Water cooldown active (8 hours)");
        require(plant.growthStage < 3, "Plant already mature");
        
        plant.lastWatered = block.timestamp;
        plant.waterCount += 1;
        waterCount[tokenId] += 1;

        emit PlantWatered(tokenId, block.timestamp);
        
        // Auto-grow if requirements are met
        if (canGrow(tokenId)) {
            _growPlant(tokenId);
        }
    }

    function canGrow(uint256 tokenId) public view returns (bool) {
        PlantMetaData memory plant = plants[tokenId];
        
        // Check if already mature (max stage: 3)
        if (plant.growthStage >= 3) return false;
        
        // Check time requirement: 1 day per stage (adjusted by growth boost)
        uint256 timeRequired = STAGE_DURATION / growthBoost[tokenId];
        if (block.timestamp - plant.plantedAt < (plant.growthStage + 1) * timeRequired) return false;
        
        // Check waterings requirement: 3 waterings per stage
        if (waterCount[tokenId] < (plant.growthStage + 1) * WATERINGS_PER_STAGE) return false;
        
        return true;
    }

    function growPlant(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(canGrow(tokenId), "Growth requirements not met");
        
        _growPlant(tokenId);
    }
    
    // Internal function to handle growth
    function _growPlant(uint256 tokenId) internal {
        PlantMetaData storage plant = plants[tokenId];
        plant.growthStage++;
        lastGrowthTime[tokenId] = block.timestamp;

        emit PlantGrown(tokenId, plant.growthStage);
    }

    /**
     * Harvest mature plants for GardenToken rewards
     * After harvest: allow continuous harvest with cooldown
     */
    function harvestPlant(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(plants[tokenId].growthStage == 3, "Plant not mature");
        require(address(gardenToken) != address(0), "GardenToken not set");
        require(
            block.timestamp >= lastHarvestTime[tokenId] + HARVEST_COOLDOWN,
            "Harvest cooldown active (1 day)"
        );

        // Calculate reward based on plant rarity
        PlantMetaData memory plant = plants[tokenId];
        uint256 reward = _calculateHarvestReward(plant.rarity);
        
        // Update harvest timestamp for cooldown
        lastHarvestTime[tokenId] = block.timestamp;
        
        // Mint reward to player
        gardenToken.mintReward(msg.sender, reward);

        emit PlantHarvested(tokenId, msg.sender, reward);
    }
    
    // Internal function to calculate harvest reward using GardenToken logic
    function _calculateHarvestReward(uint8 rarity) internal pure returns (uint256) {
        // Base reward = 10 GDN, with rarity multipliers
        uint256 baseReward = 10 * 10**18; // 10 GDN base
        
        // Rarity multiplier
        uint256 rarityMultiplier;
        if (rarity == 1) rarityMultiplier = 1; // Common
        else if (rarity == 2) rarityMultiplier = 2; // Rare
        else if (rarity == 3) rarityMultiplier = 3; // Epic
        else if (rarity == 4) rarityMultiplier = 5; // Legendary
        else if (rarity == 5) rarityMultiplier = 10; // Mythic
        else rarityMultiplier = 1; // Default to Common
        
        // Only mature plants can be harvested, so always 1x multiplier
        return baseReward * rarityMultiplier;
    }

    // Legacy function - kept for backward compatibility
    // Use GardenToken.calculateReward() for accurate reward calculation
    function calculateReward(uint256 tokenId) public view returns (uint256) {
        PlantMetaData memory plant = plants[tokenId];
        return _calculateHarvestReward(plant.rarity);
    }

    // Use fertilizer item to boost growth
    function useFertilizer(uint256 plantId, uint256 itemId) external {
        require(ownerOf(plantId) == msg.sender, "Not owner");
        require(address(gameItems) != address(0), "GameItems not set");
        require(gameItems.balanceOf(msg.sender, itemId) > 0, "No item");
        require(plants[plantId].growthStage < 3, "Plant already mature");

        gameItems.burn(msg.sender, itemId, 1); // Burn item
        growthBoost[plantId] = 2; // 2x growth speed

        emit FertilizerUsed(plantId, itemId, 2);
    }
    
    /**
     * Use items from GameItems contract on plants
     */
    function useItemOnPlant(uint256 plantId, uint256 itemId) external {
        require(ownerOf(plantId) == msg.sender, "Not plant owner");
        require(address(gameItems) != address(0), "GameItems contract not set");
        require(gameItems.balanceOf(msg.sender, itemId) > 0, "Insufficient item balance");
        
        PlantMetaData storage plant = plants[plantId];
        
        // Apply item effect based on itemId
        if (itemId == 1) {
            // Growth Boost item
            require(plant.growthStage < 3, "Plant already mature");
            growthBoost[plantId] = 2; // 2x growth speed
            emit FertilizerUsed(plantId, itemId, 2);
        } else if (itemId == 2) {
            // Water Boost item - add extra waterings
            require(plant.growthStage < 3, "Plant already mature");
            plant.waterCount += 2;
            waterCount[plantId] += 2;
        } else if (itemId == 3) {
            // Instant Growth item - skip time requirement
            if (waterCount[plantId] >= (plant.growthStage + 1) * WATERINGS_PER_STAGE && plant.growthStage < 3) {
                _growPlant(plantId);
            }
        } else {
            // Generic item - provide small growth boost
            growthBoost[plantId] = (growthBoost[plantId] * 120) / 100; // 20% boost
        }
        
        // Burn the item after use
        gameItems.burn(msg.sender, itemId, 1);
    }

    // ============ VIEW FUNCTIONS ============
    
    function canHarvest(uint256 tokenId) public view returns (bool) {
        PlantMetaData memory plant = plants[tokenId];
        return plant.growthStage == 3 && 
               block.timestamp >= lastHarvestTime[tokenId] + HARVEST_COOLDOWN;
    }
    
    function getTimeUntilHarvest(uint256 tokenId) public view returns (uint256) {
        uint256 nextHarvestTime = lastHarvestTime[tokenId] + HARVEST_COOLDOWN;
        return nextHarvestTime > block.timestamp ? nextHarvestTime - block.timestamp : 0;
    }
    
    function getTimeUntilWater(uint256 tokenId) public view returns (uint256) {
        PlantMetaData memory plant = plants[tokenId];
        uint256 nextWaterTime = plant.lastWatered + WATER_COOLDOWN;
        return nextWaterTime > block.timestamp ? nextWaterTime - block.timestamp : 0;
    }

    function getPlant(uint256 tokenId) external view returns (PlantMetaData memory)
    {
        require(ownerOf(tokenId) != address(0), "Token doesn't exist");
        return plants[tokenId];
    }

    /**
     * @dev Get all plants owned by address
     * TODO: Optimize for large collections (HOMEWORK!)
     */
    function getPlantsOfOwner(address owner) external view returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner);
        uint256[] memory ownedTokens = new uint256[](balance);

        uint256 index = 0;
        for (uint256 i = 0; i < _nextTokenId; i++) {
            if (_ownerOf(i) == owner) {
                ownedTokens[index] = i;
                index++;
            }
        }
        return ownedTokens;
    }
}