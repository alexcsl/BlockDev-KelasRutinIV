// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title LiskGarden
 * @dev Main game contract yang orchestrate semua token contracts
 */
contract LiskGarden {

    address public immutable gardenToken;
    address public immutable plantNFT;
    address public immutable gameItems;

    address public owner;

    // Game constants
    uint256 public constant PLANT_COST = 0.001 ether;
    uint256 public constant SEED_ITEM_ID = 0;
    uint256 public constant WATER_CAN_ITEM_ID = 2;
    uint256 public constant FERTILIZER_ITEM_ID = 1;

    // Game state
    uint256 public treasuryBalance;
    uint256 public totalPlantsMinted;
    uint256 public totalHarvests;
    uint256 public totalGDNMinted;

    // Player stats
    mapping(address => uint256) public totalHarvested;
    mapping(address => uint256) public totalPlantsOwned;

    // Achievements system
    enum Achievement {
        FIRST_PLANT,        // 0
        TENTH_PLANT,        // 1
        HUNDREDTH_PLANT,    // 2
        FIRST_LEGENDARY,    // 3
        MASTER_FARMER       // 4
    }

    mapping(address => mapping(Achievement => bool)) public achievements;
    mapping(address => mapping(Achievement => uint256)) public achievementTimestamp;

    // Events
    event PlantSeeded(address indexed player, uint256 indexed plantId, string name, string species);
    event PlantWatered(address indexed player, uint256 indexed plantId);
    event FertilizerUsed(address indexed player, uint256 indexed plantId);
    event PlantHarvested(address indexed player, uint256 indexed plantId, uint256 reward);
    event AchievementUnlocked(address indexed player, Achievement indexed achievement, uint256 timestamp);
    event TreasuryUpdated(uint256 newBalance);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(
        address _gardenToken,
        address _plantNFT,
        address _gameItems
    ) {
        require(_gardenToken != address(0), "Invalid GardenToken address");
        require(_plantNFT != address(0), "Invalid PlantNFT address");
        require(_gameItems != address(0), "Invalid GameItems address");

        gardenToken = _gardenToken;
        plantNFT = _plantNFT;
        gameItems = _gameItems;
        owner = msg.sender;
    }

    // ============ CORE GAME FUNCTIONS ============

    /**
     * 1. Plant a seed (requires SEED item + ETH)
     */
    function plantSeed(string memory name, string memory species)
        external
        payable
        returns (uint256)
    {
        require(msg.value >= PLANT_COST, "Insufficient payment");
        
        // Check if player has seed item using low-level call
        (bool success, bytes memory data) = gameItems.call(
            abi.encodeWithSignature("balanceOf(address,uint256)", msg.sender, SEED_ITEM_ID)
        );
        require(success && abi.decode(data, (uint256)) > 0, "No seed item");

        // Burn seed item using low-level call
        (success,) = gameItems.call(
            abi.encodeWithSignature("burn(address,uint256,uint256)", msg.sender, SEED_ITEM_ID, 1)
        );
        require(success, "Failed to burn seed");

        // Mint PlantNFT using low-level call
        (success, data) = plantNFT.call(
            abi.encodeWithSignature("mintPlant(string,string)", name, species)
        );
        require(success, "Failed to mint plant");
        uint256 plantId = abi.decode(data, (uint256));

        // Update stats
        totalPlantsMinted++;
        totalPlantsOwned[msg.sender]++;
        treasuryBalance += msg.value;

        // Check achievements
        checkAndUnlockAchievements(msg.sender);

        emit PlantSeeded(msg.sender, plantId, name, species);
        emit TreasuryUpdated(treasuryBalance);

        return plantId;
    }

    /**
     * 2. Water plant (requires WATER_CAN item or cooldown)
     */
    function waterPlant(uint256 plantId) external {
        // Check ownership using low-level call
        (bool success, bytes memory data) = plantNFT.call(
            abi.encodeWithSignature("ownerOf(uint256)", plantId)
        );
        require(success && abi.decode(data, (address)) == msg.sender, "Not owner");

        // Check if player has water can
        (success, data) = gameItems.call(
            abi.encodeWithSignature("balanceOf(address,uint256)", msg.sender, WATER_CAN_ITEM_ID)
        );
        bool hasWaterCan = success && abi.decode(data, (uint256)) > 0;
        
        if (hasWaterCan) {
            // Use water can for instant watering (no cooldown)
            (success,) = gameItems.call(
                abi.encodeWithSignature("burn(address,uint256,uint256)", msg.sender, WATER_CAN_ITEM_ID, 1)
            );
            require(success, "Failed to burn water can");
        }

        // Water the plant
        (success,) = plantNFT.call(
            abi.encodeWithSignature("waterPlant(uint256)", plantId)
        );
        require(success, "Failed to water plant");

        emit PlantWatered(msg.sender, plantId);
    }

    /**
     * 3. Use fertilizer (requires FERTILIZER item)
     */
    function useFertilizer(uint256 plantId) external {
        // Check ownership
        (bool success, bytes memory data) = plantNFT.call(
            abi.encodeWithSignature("ownerOf(uint256)", plantId)
        );
        require(success && abi.decode(data, (address)) == msg.sender, "Not owner");

        // Check fertilizer balance
        (success, data) = gameItems.call(
            abi.encodeWithSignature("balanceOf(address,uint256)", msg.sender, FERTILIZER_ITEM_ID)
        );
        require(success && abi.decode(data, (uint256)) > 0, "No fertilizer");

        // Use fertilizer item
        (success,) = gameItems.call(
            abi.encodeWithSignature("useItem(uint256,uint256)", plantId, FERTILIZER_ITEM_ID)
        );
        require(success, "Failed to use fertilizer");

        emit FertilizerUsed(msg.sender, plantId);
    }

    /**
     * 4. Harvest mature plant
     */
    function harvestPlant(uint256 plantId) external {
        // Check ownership
        (bool success, bytes memory data) = plantNFT.call(
            abi.encodeWithSignature("ownerOf(uint256)", plantId)
        );
        require(success && abi.decode(data, (address)) == msg.sender, "Not owner");

        // Check if plant can be harvested
        (success, data) = plantNFT.call(
            abi.encodeWithSignature("canHarvest(uint256)", plantId)
        );
        require(success && abi.decode(data, (bool)), "Cannot harvest yet");

        // Harvest through PlantNFT
        (success,) = plantNFT.call(
            abi.encodeWithSignature("harvestPlant(uint256)", plantId)
        );
        require(success, "Failed to harvest plant");

        // Estimate reward (simplified calculation)
        uint256 reward = 100 * 10**18; // 100 GDN base reward

        // Update stats
        totalHarvests++;
        totalHarvested[msg.sender] += reward;
        totalGDNMinted += reward;

        // Check achievements
        checkAndUnlockAchievements(msg.sender);

        emit PlantHarvested(msg.sender, plantId, reward);
    }

    /**
     * 5. Batch operations - Harvest all mature plants
     */
    function harvestAll() external {
        // Get plants owned by user
        (bool success, bytes memory data) = plantNFT.call(
            abi.encodeWithSignature("getPlantsOfOwner(address)", msg.sender)
        );
        require(success, "Failed to get owned plants");
        
        uint256[] memory ownedPlants = abi.decode(data, (uint256[]));
        uint256 totalReward = 0;
        uint256 harvestedCount = 0;

        for (uint256 i = 0; i < ownedPlants.length; i++) {
            uint256 plantId = ownedPlants[i];
            
            // Check if plant can be harvested
            (success, data) = plantNFT.call(
                abi.encodeWithSignature("canHarvest(uint256)", plantId)
            );
            
            if (success && abi.decode(data, (bool))) {
                // Harvest individual plant
                (success,) = plantNFT.call(
                    abi.encodeWithSignature("harvestPlant(uint256)", plantId)
                );
                
                if (success) {
                    uint256 reward = 100 * 10**18; // Base reward
                    totalReward += reward;
                    harvestedCount++;
                    
                    emit PlantHarvested(msg.sender, plantId, reward);
                }
            }
        }

        require(harvestedCount > 0, "No plants ready for harvest");

        // Update stats
        totalHarvests += harvestedCount;
        totalHarvested[msg.sender] += totalReward;
        totalGDNMinted += totalReward;

        // Check achievements
        checkAndUnlockAchievements(msg.sender);
    }

    // ============ ACHIEVEMENTS SYSTEM ============

    function checkAndUnlockAchievements(address player) internal {
        uint256 currentTimestamp = block.timestamp;

        // First Plant Achievement
        if (!achievements[player][Achievement.FIRST_PLANT] && totalPlantsOwned[player] >= 1) {
            achievements[player][Achievement.FIRST_PLANT] = true;
            achievementTimestamp[player][Achievement.FIRST_PLANT] = currentTimestamp;
            
            // Bonus reward: 50 GDN
            (bool success,) = gardenToken.call(
                abi.encodeWithSignature("mintReward(address,uint256)", player, 50 * 10**18)
            );
            
            if (success) {
                emit AchievementUnlocked(player, Achievement.FIRST_PLANT, currentTimestamp);
            }
        }

        // Tenth Plant Achievement
        if (!achievements[player][Achievement.TENTH_PLANT] && totalPlantsOwned[player] >= 10) {
            achievements[player][Achievement.TENTH_PLANT] = true;
            achievementTimestamp[player][Achievement.TENTH_PLANT] = currentTimestamp;
            
            // Bonus reward: 500 GDN
            (bool success,) = gardenToken.call(
                abi.encodeWithSignature("mintReward(address,uint256)", player, 500 * 10**18)
            );
            
            if (success) {
                emit AchievementUnlocked(player, Achievement.TENTH_PLANT, currentTimestamp);
            }
        }

        // Hundredth Plant Achievement
        if (!achievements[player][Achievement.HUNDREDTH_PLANT] && totalPlantsOwned[player] >= 100) {
            achievements[player][Achievement.HUNDREDTH_PLANT] = true;
            achievementTimestamp[player][Achievement.HUNDREDTH_PLANT] = currentTimestamp;
            
            // Bonus reward: 5000 GDN
            (bool success,) = gardenToken.call(
                abi.encodeWithSignature("mintReward(address,uint256)", player, 5000 * 10**18)
            );
            
            if (success) {
                emit AchievementUnlocked(player, Achievement.HUNDREDTH_PLANT, currentTimestamp);
            }
        }

        // Master Farmer Achievement (1000 total harvested)
        if (!achievements[player][Achievement.MASTER_FARMER] && totalHarvested[player] >= 1000 * 10**18) {
            achievements[player][Achievement.MASTER_FARMER] = true;
            achievementTimestamp[player][Achievement.MASTER_FARMER] = currentTimestamp;
            
            // Bonus reward: 10000 GDN
            (bool success,) = gardenToken.call(
                abi.encodeWithSignature("mintReward(address,uint256)", player, 10000 * 10**18)
            );
            
            if (success) {
                emit AchievementUnlocked(player, Achievement.MASTER_FARMER, currentTimestamp);
            }
        }

        // First Legendary Achievement - simplified check
        // Note: This would need more sophisticated logic to check plant rarity
        // For now, we'll unlock this achievement after the 10th plant as a placeholder
        if (!achievements[player][Achievement.FIRST_LEGENDARY] && totalPlantsOwned[player] >= 5) {
            achievements[player][Achievement.FIRST_LEGENDARY] = true;
            achievementTimestamp[player][Achievement.FIRST_LEGENDARY] = currentTimestamp;
            
            // Bonus reward: 1000 GDN
            (bool success,) = gardenToken.call(
                abi.encodeWithSignature("mintReward(address,uint256)", player, 1000 * 10**18)
            );
            
            if (success) {
                emit AchievementUnlocked(player, Achievement.FIRST_LEGENDARY, currentTimestamp);
            }
        }
    }

    // ============ LEADERBOARD ============

    function getTopFarmers(uint256 /* count */)
        external
        pure
        returns (address[] memory farmers, uint256[] memory harvests)
    {
        // Note: This is a simple implementation. For production, consider using
        // a more efficient data structure like a sorted list or heap
        
        // This function would need to iterate through all addresses that have harvested
        // For now, returning empty arrays as a placeholder
        farmers = new address[](0);
        harvests = new uint256[](0);
        
        // TODO: Implement proper leaderboard tracking
        // This would require maintaining a list of all players and sorting them
    }

    // ============ TREASURY & ECONOMICS ============

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        treasuryBalance = 0;
        payable(owner).transfer(balance);
        
        emit TreasuryUpdated(0);
    }

    function updateMintCost(uint256 newCost) external onlyOwner {
        // This would require updating the PlantNFT contract's mint cost
        // For now, we'll emit an event to indicate the intention
        // The actual implementation would depend on how PlantNFT is structured
    }

    // ============ GAME STATISTICS ============

    struct GameStats {
        uint256 totalPlantsMinted;
        uint256 totalHarvests;
        uint256 totalGDNMinted;
        uint256 totalItemsSold;
    }

    function getGameStats() external view returns (GameStats memory) {
        return GameStats({
            totalPlantsMinted: totalPlantsMinted,
            totalHarvests: totalHarvests,
            totalGDNMinted: totalGDNMinted,
            totalItemsSold: 0 // Would need to track this in GameItems contract
        });
    }

    // ============ PLAYER STATISTICS ============

    function getPlayerStats(address player) 
        external 
        view 
        returns (
            uint256 plantsOwned,
            uint256 totalHarvestedAmount,
            uint256 achievementCount
        ) 
    {
        plantsOwned = totalPlantsOwned[player];
        totalHarvestedAmount = totalHarvested[player];
        
        // Count achievements
        achievementCount = 0;
        for (uint256 i = 0; i < 5; i++) {
            if (achievements[player][Achievement(i)]) {
                achievementCount++;
            }
        }
        
        return (plantsOwned, totalHarvestedAmount, achievementCount);
    }

    function getPlayerAchievements(address player) 
        external 
        view 
        returns (bool[] memory unlocked, uint256[] memory timestamps) 
    {
        unlocked = new bool[](5);
        timestamps = new uint256[](5);
        
        for (uint256 i = 0; i < 5; i++) {
            Achievement achievement = Achievement(i);
            unlocked[i] = achievements[player][achievement];
            timestamps[i] = achievementTimestamp[player][achievement];
        }
        
        return (unlocked, timestamps);
    }

    // ============ UTILITY FUNCTIONS ============

    function getContractAddresses() 
        external 
        view 
        returns (address gardenTokenAddr, address plantNFTAddr, address gameItemsAddr) 
    {
        return (address(gardenToken), address(plantNFT), address(gameItems));
    }

    // Emergency functions
    function emergencyPause() external onlyOwner {
        // Implement pause functionality if needed
    }

    // Receive ETH
    receive() external payable {
        treasuryBalance += msg.value;
        emit TreasuryUpdated(treasuryBalance);
    }
}