// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GameItemsSkeleton
 * @dev Foundation untuk LiskGarden game items - akan dilengkapi di homework
 */
contract GameItemsSkeleton is ERC1155, Ownable {

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

    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public maxSupply;

    /**
     * @dev Item effects (untuk game mechanics)
     * TODO: Implement effect system (HOMEWORK!)
     */
    struct ItemEffect {
        uint256 growthMultiplier;   // 100 = 1x, 200 = 2x
        uint256 rarityBoost;        // Percentage boost
        uint256 durationSeconds;    // Untuk timed boosts
        bool isConsumable;          // Habis pakai atau permanent
    }

    mapping(uint256 => ItemEffect) public itemEffects;

    /**
     * @dev Track active boosts per player per plant
     * TODO: Implement boost tracking (HOMEWORK!)
     */
    mapping(address => mapping(uint256 => uint256)) public activeBoosts;

    // ============ EVENTS ============

    event ItemPurchased(address indexed buyer, uint256 indexed id, uint256 amount);
    event ItemUsed(address indexed user, uint256 indexed plantId, uint256 indexed itemId);
    event BoostActivated(address indexed user, uint256 indexed plantId, uint256 boost);

    // ============ CONSTRUCTOR ============

    constructor()
        ERC1155("https://api.liskgarden.example/item/{id}.json")
        Ownable(msg.sender)
    {
        _initializeItems();
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

        // TODO: Set item effects (HOMEWORK!)
        // itemEffects[FERTILIZER] = ItemEffect(200, 0, 0, true);  // 2x growth
        // itemEffects[GROWTH_BOOST_1H] = ItemEffect(300, 0, 3600, true);  // 3x for 1h
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
     * TODO: Implement usage logic (HOMEWORK!)
     */
    function useItem(uint256 plantId, uint256 itemId) external {
        require(balanceOf(msg.sender, itemId) > 0, "Don't have item");

        // TODO: Verify ownership of plantId
        // TODO: Apply item effect to plant
        // TODO: If consumable, burn item
        // TODO: If timed boost, track expiry

        // For now, just burn if consumable
        // _burn(msg.sender, itemId, 1);

        emit ItemUsed(msg.sender, plantId, itemId);
    }

    /**
     * @dev Batch use items
     * TODO: Implement batch usage (HOMEWORK!)
     */
    function useItemBatch(
        uint256 plantId,
        uint256[] memory itemIds,
        uint256[] memory amounts
    ) external {
        // TODO: Implement efficient batch item usage
    }

    // ============ VIEW FUNCTIONS ============

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

    function setItemPrice(uint256 id, uint256 price) external onlyOwner {
        itemPrice[id] = price;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}