// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Interface for PlantNFT integration
interface IPlantNFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function applyGrowthBoost(uint256 plantId, uint256 multiplier) external;
}

/**
 * @title GameItemsSkeleton
 * @dev Complete LiskGarden game items with boost tracking and effect system
 */
contract GameItems is ERC1155, Ownable {

    // ============ ITEM CATEGORIES ============

    // Consumables (unlimited supply)
    uint256 public constant SEED = 0;
    uint256 public constant FERTILIZER = 1;
    uint256 public constant WATER_CAN = 2;
    uint256 public constant PESTICIDE = 3;

    // Tools (limited supply)
    uint256 public constant GOLDEN_SHOVEL = 10;      // Rare
    uint256 public constant RAINBOW_WATERING_CAN = 11;  // Epic
    uint256 public constant MYSTICAL_FERTILIZER = 12;   // Legendary

    // Boosts (consumable, limited)
    uint256 public constant GROWTH_BOOST_1H = 20;    // 1 hour boost
    uint256 public constant GROWTH_BOOST_24H = 21;   // 24 hour boost
    uint256 public constant RARE_SEED_BOOST = 22;    // Increase rarity chance

    // ============ STATE ============

    // Contract references
    address public plantNFTAddress;
    IPlantNFT public plantNFT;

    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public maxSupply;

    /**
     * @dev Item effects for game mechanics
     */
    struct ItemEffect {
        uint256 growthMultiplier;   // 100 = 1x, 200 = 2x
        uint256 rarityBoost;        // Percentage boost
        uint256 durationSeconds;    // For timed boosts
        bool isConsumable;          // Consumable or permanent
    }

    mapping(uint256 => ItemEffect) public itemEffects;

    /**
     * @dev Track active boosts with expiry
     */
    struct ActiveBoost {
        uint256 itemId;
        uint256 expiryTime;
        uint256 multiplier;
    }

    mapping(address => mapping(uint256 => ActiveBoost[])) public activeBoosts;

    /**
     * Track item usage statistics
     */
    mapping(uint256 => uint256) public itemUsageCount;
    mapping(address => mapping(uint256 => uint256)) public playerItemUsage;

    // ============ EVENTS ============

    event ItemPurchased(address indexed buyer, uint256 indexed id, uint256 amount);
    event ItemUsed(
        address indexed player,
        uint256 indexed plantId,
        uint256 indexed itemId,
        uint256 timestamp
    );
    event BoostActivated(address indexed user, uint256 indexed plantId, uint256 boost, uint256 expiryTime);
    event BoostExpired(address indexed user, uint256 indexed plantId, uint256 itemId);

    // ============ CONSTRUCTOR ============

    constructor()
        ERC1155("https://api.liskgarden.example/item/{id}.json")
        Ownable(msg.sender)
    {
        _initializeItems();
        _initializeItemEffects();
    }

    function _initializeItems() private {
        // Set prices
        itemPrice[SEED] = 0.0001 ether;
        itemPrice[FERTILIZER] = 0.0002 ether;
        itemPrice[WATER_CAN] = 0.0003 ether;
        itemPrice[PESTICIDE] = 0.0002 ether;
        itemPrice[GOLDEN_SHOVEL] = 0.01 ether;
        itemPrice[RAINBOW_WATERING_CAN] = 0.02 ether;
        itemPrice[MYSTICAL_FERTILIZER] = 0.05 ether;
        itemPrice[GROWTH_BOOST_1H] = 0.001 ether;
        itemPrice[GROWTH_BOOST_24H] = 0.005 ether;
        itemPrice[RARE_SEED_BOOST] = 0.003 ether;

        // Set max supplies
        maxSupply[GOLDEN_SHOVEL] = 1000;
        maxSupply[RAINBOW_WATERING_CAN] = 500;
        maxSupply[MYSTICAL_FERTILIZER] = 100;

        // Set item effects
        itemEffects[FERTILIZER] = ItemEffect({
            growthMultiplier: 200,    // 2x growth speed
            rarityBoost: 0,
            durationSeconds: 0,       // Instant effect
            isConsumable: true
        });

        itemEffects[GROWTH_BOOST_1H] = ItemEffect({
            growthMultiplier: 300,    // 3x growth speed
            rarityBoost: 0,
            durationSeconds: 3600,    // 1 hour
            isConsumable: true
        });

        itemEffects[GROWTH_BOOST_24H] = ItemEffect({
            growthMultiplier: 250,    // 2.5x growth speed
            rarityBoost: 0,
            durationSeconds: 86400,   // 24 hours
            isConsumable: true
        });

        itemEffects[RARE_SEED_BOOST] = ItemEffect({
            growthMultiplier: 100,    // 1x growth (no change)
            rarityBoost: 20,          // 20% rarity boost
            durationSeconds: 0,       // Instant effect
            isConsumable: true
        });

        itemEffects[MYSTICAL_FERTILIZER] = ItemEffect({
            growthMultiplier: 500,    // 5x growth speed
            rarityBoost: 10,          // 10% rarity boost
            durationSeconds: 0,       // Instant effect
            isConsumable: true
        });
    }

    /**
     * Define effects for each item type
     */
    function _initializeItemEffects() private {
        // Fertilizer: 2x growth, instant, consumable
        itemEffects[FERTILIZER] = ItemEffect(200, 0, 0, true);

        // Growth Boost 1H: 3x growth, 1 hour, consumable
        itemEffects[GROWTH_BOOST_1H] = ItemEffect(300, 0, 3600, true);

        // Growth Boost 24H: 2.5x growth, 24 hours, consumable
        itemEffects[GROWTH_BOOST_24H] = ItemEffect(250, 0, 86400, true);

        // Water Can: 1.5x growth, instant, reusable
        itemEffects[WATER_CAN] = ItemEffect(150, 0, 0, false);

        // Pesticide: 1.2x growth, rarity boost, instant, consumable
        itemEffects[PESTICIDE] = ItemEffect(120, 5, 0, true);

        // Golden Shovel: 2x growth, permanent tool
        itemEffects[GOLDEN_SHOVEL] = ItemEffect(200, 0, 0, false);

        // Rainbow Watering Can: 3x growth, permanent tool
        itemEffects[RAINBOW_WATERING_CAN] = ItemEffect(300, 0, 0, false);

        // Mystical Fertilizer: 5x growth, 10% rarity boost, instant, consumable
        itemEffects[MYSTICAL_FERTILIZER] = ItemEffect(500, 10, 0, true);

        // Rare Seed Boost: no growth bonus, 20% rarity boost, instant, consumable
        itemEffects[RARE_SEED_BOOST] = ItemEffect(100, 20, 0, true);

        // Seed: basic item, no special effects
        itemEffects[SEED] = ItemEffect(100, 0, 0, true);
    }

    // ============ BUY FUNCTIONS ============

    function buyItem(uint256 id, uint256 amount) external payable {
        uint256 cost = itemPrice[id] * amount;
        require(msg.value >= cost, "Insufficient payment");

        // Check max supply
        if (maxSupply[id] > 0) {
            require(totalSupply[id] + amount <= maxSupply[id], "Sold out");
        }

        _mint(msg.sender, id, amount, "");
        totalSupply[id] += amount;

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit ItemPurchased(msg.sender, id, amount);
    }

    function buyBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable {
        require(ids.length == amounts.length, "Length mismatch");

        uint256 totalCost = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            totalCost += itemPrice[ids[i]] * amounts[i];

            if (maxSupply[ids[i]] > 0) {
                require(totalSupply[ids[i]] + amounts[i] <= maxSupply[ids[i]], "Sold out");
            }

            totalSupply[ids[i]] += amounts[i];
        }

        require(msg.value >= totalCost, "Insufficient payment");
        _mintBatch(msg.sender, ids, amounts, "");

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    // ============ GAME FUNCTIONS ============

    /**
     * @dev Use item on plant
     */
    function useItem(uint256 plantId, uint256 itemId) external {
        // 1. Verify ownership
        require(plantNFTAddress != address(0), "PlantNFT not set");
        require(plantNFT.ownerOf(plantId) == msg.sender, "Not owner");

        // 2. Check item balance
        require(balanceOf(msg.sender, itemId) > 0, "No item");

        // 3. Apply effect
        ItemEffect memory effect = itemEffects[itemId];
        require(effect.growthMultiplier > 0 || effect.rarityBoost > 0, "Invalid item");

        if (effect.durationSeconds > 0) {
            // Timed boost
            activeBoosts[msg.sender][plantId].push(ActiveBoost({
                itemId: itemId,
                expiryTime: block.timestamp + effect.durationSeconds,
                multiplier: effect.growthMultiplier
            }));

            emit BoostActivated(msg.sender, plantId, effect.growthMultiplier, block.timestamp + effect.durationSeconds);
        } else {
            // Instant effect - apply directly to plant growth
            if (effect.growthMultiplier > 100) {
                plantNFT.applyGrowthBoost(plantId, effect.growthMultiplier);
            }
        }

        // 4. Burn if consumable
        if (effect.isConsumable) {
            _burn(msg.sender, itemId, 1);
        }

        // 5. Update analytics
        itemUsageCount[itemId]++;
        playerItemUsage[msg.sender][itemId]++;

        emit ItemUsed(msg.sender, plantId, itemId, block.timestamp);
    }

    /**
     * @dev Use fertilizer specifically (legacy function)
     */
    function useFertilizer(uint256 plantId) external {
        require(balanceOf(msg.sender, FERTILIZER) > 0, "No fertilizer");
        require(plantNFTAddress != address(0), "PlantNFT not set");
        require(plantNFT.ownerOf(plantId) == msg.sender, "Not owner");

        // Call PlantNFT to boost growth
        plantNFT.applyGrowthBoost(plantId, 200); // 2x

        // Burn fertilizer
        _burn(msg.sender, FERTILIZER, 1);

        // Update analytics
        itemUsageCount[FERTILIZER]++;
        playerItemUsage[msg.sender][FERTILIZER]++;

        emit ItemUsed(msg.sender, plantId, FERTILIZER, block.timestamp);
    }

    /**
     * @dev Batch use items
     */
    function useItemBatch(
        uint256 plantId,
        uint256[] memory itemIds,
        uint256[] memory amounts
    ) external {
        require(itemIds.length == amounts.length, "Length mismatch");
        require(plantNFTAddress != address(0), "PlantNFT not set");
        require(plantNFT.ownerOf(plantId) == msg.sender, "Not owner");

        for (uint256 i = 0; i < itemIds.length; i++) {
            uint256 itemId = itemIds[i];
            uint256 amount = amounts[i];
            
            require(balanceOf(msg.sender, itemId) >= amount, "Insufficient item balance");
            
            ItemEffect memory effect = itemEffects[itemId];
            
            for (uint256 j = 0; j < amount; j++) {
                if (effect.durationSeconds > 0) {
                    // Timed boost
                    activeBoosts[msg.sender][plantId].push(ActiveBoost({
                        itemId: itemId,
                        expiryTime: block.timestamp + effect.durationSeconds,
                        multiplier: effect.growthMultiplier
                    }));
                } else {
                    // Instant effect
                    if (effect.growthMultiplier > 100) {
                        plantNFT.applyGrowthBoost(plantId, effect.growthMultiplier);
                    }
                }
            }
            
            if (effect.isConsumable) {
                _burn(msg.sender, itemId, amount);
            }

            // Update analytics for batch usage
            itemUsageCount[itemId] += amount;
            playerItemUsage[msg.sender][itemId] += amount;

            emit ItemUsed(msg.sender, plantId, itemId, block.timestamp);
        }
    }

    /**
     * @dev Get effective growth rate considering all active boosts
     */
    function getEffectiveGrowthRate(address user, uint256 plantId)
        public
        view
        returns (uint256)
    {
        uint256 totalMultiplier = 100; // Base 1x
        ActiveBoost[] memory boosts = activeBoosts[user][plantId];
        
        for (uint256 i = 0; i < boosts.length; i++) {
            if (boosts[i].expiryTime > block.timestamp) {
                // Boost is still active
                totalMultiplier += (boosts[i].multiplier - 100); // Add bonus multiplier
            }
        }
        
        return totalMultiplier;
    }

    /**
     * @dev Clean expired boosts for gas optimization
     */
    function cleanExpiredBoosts(address user, uint256 plantId) external {
        ActiveBoost[] storage boosts = activeBoosts[user][plantId];
        
        for (uint256 i = 0; i < boosts.length; i++) {
            if (boosts[i].expiryTime <= block.timestamp) {
                emit BoostExpired(user, plantId, boosts[i].itemId);
                
                // Remove expired boost by swapping with last element
                boosts[i] = boosts[boosts.length - 1];
                boosts.pop();
                i--; // Adjust index after removal
            }
        }
    }

    /**
     * @dev Get all active boosts for a user and plant
     */
    function getActiveBoosts(address user, uint256 plantId) 
        external 
        view 
        returns (ActiveBoost[] memory) 
    {
        ActiveBoost[] memory allBoosts = activeBoosts[user][plantId];
        
        // Count active (non-expired) boosts
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allBoosts.length; i++) {
            if (allBoosts[i].expiryTime > block.timestamp) {
                activeCount++;
            }
        }
        
        // Create array with only active boosts
        ActiveBoost[] memory result = new ActiveBoost[](activeCount);
        uint256 resultIndex = 0;
        
        for (uint256 i = 0; i < allBoosts.length; i++) {
            if (allBoosts[i].expiryTime > block.timestamp) {
                result[resultIndex] = allBoosts[i];
                resultIndex++;
            }
        }
        
        return result;
    }

    // ============ VIEW FUNCTIONS ============

    function getMostUsedItems(uint256 count)
        external
        view
        returns (uint256[] memory itemIds, uint256[] memory usageCounts)
    {
        // Create arrays to store all item data
        uint256[] memory allItemIds = new uint256[](13); // We have 13 item types
        uint256[] memory allUsageCounts = new uint256[](13);
        
        // Populate with all items and their usage counts
        allItemIds[0] = SEED;
        allItemIds[1] = FERTILIZER;
        allItemIds[2] = WATER_CAN;
        allItemIds[3] = PESTICIDE;
        allItemIds[4] = GOLDEN_SHOVEL;
        allItemIds[5] = RAINBOW_WATERING_CAN;
        allItemIds[6] = MYSTICAL_FERTILIZER;
        allItemIds[7] = GROWTH_BOOST_1H;
        allItemIds[8] = GROWTH_BOOST_24H;
        allItemIds[9] = RARE_SEED_BOOST;
        
        for (uint256 i = 0; i < 10; i++) {
            allUsageCounts[i] = itemUsageCount[allItemIds[i]];
        }
        
        // Simple bubble sort to get top items (good enough for small dataset)
        for (uint256 i = 0; i < 10; i++) {
            for (uint256 j = i + 1; j < 10; j++) {
                if (allUsageCounts[j] > allUsageCounts[i]) {
                    // Swap usage counts
                    uint256 tempCount = allUsageCounts[i];
                    allUsageCounts[i] = allUsageCounts[j];
                    allUsageCounts[j] = tempCount;
                    
                    // Swap item IDs
                    uint256 tempId = allItemIds[i];
                    allItemIds[i] = allItemIds[j];
                    allItemIds[j] = tempId;
                }
            }
        }
        
        // Return top N items
        uint256 resultCount = count > 10 ? 10 : count;
        itemIds = new uint256[](resultCount);
        usageCounts = new uint256[](resultCount);
        
        for (uint256 i = 0; i < resultCount; i++) {
            itemIds[i] = allItemIds[i];
            usageCounts[i] = allUsageCounts[i];
        }
        
        return (itemIds, usageCounts);
    }

    function getItemInfo(uint256 id)
        external
        view
        returns (
            string memory name,
            uint256 price,
            uint256 supply,
            uint256 maxSupp
        )
    {
        return (
            _getItemName(id),
            itemPrice[id],
            totalSupply[id],
            maxSupply[id]
        );
    }

    function _getItemName(uint256 id) internal pure returns (string memory) {
        if (id == SEED) return "Seed";
        if (id == FERTILIZER) return "Fertilizer";
        if (id == WATER_CAN) return "Water Can";
        if (id == PESTICIDE) return "Pesticide";
        if (id == GOLDEN_SHOVEL) return "Golden Shovel";
        if (id == RAINBOW_WATERING_CAN) return "Rainbow Watering Can";
        if (id == MYSTICAL_FERTILIZER) return "Mystical Fertilizer";
        if (id == GROWTH_BOOST_1H) return "1-Hour Growth Boost";
        if (id == GROWTH_BOOST_24H) return "24-Hour Growth Boost";
        if (id == RARE_SEED_BOOST) return "Rare Seed Boost";
        return "Unknown";
    }

    // ============ ADMIN FUNCTIONS ============

    function setPlantNFT(address _plantNFTAddress) external onlyOwner {
        require(_plantNFTAddress != address(0), "Invalid address");
        plantNFTAddress = _plantNFTAddress;
        plantNFT = IPlantNFT(_plantNFTAddress);
    }

    function setItemPrice(uint256 id, uint256 price) external onlyOwner {
        itemPrice[id] = price;
    }

    function setItemEffect(
        uint256 itemId,
        uint256 growthMultiplier,
        uint256 rarityBoost,
        uint256 durationSeconds,
        bool isConsumable
    ) external onlyOwner {
        itemEffects[itemId] = ItemEffect({
            growthMultiplier: growthMultiplier,
            rarityBoost: rarityBoost,
            durationSeconds: durationSeconds,
            isConsumable: isConsumable
        });
    }

    function setMaxSupply(uint256 id, uint256 maxSupp) external onlyOwner {
        maxSupply[id] = maxSupp;
    }

    function adminMint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
        totalSupply[id] += amount;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}