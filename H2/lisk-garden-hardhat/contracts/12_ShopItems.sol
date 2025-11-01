// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ShopItems
 * @dev Game items yang bisa dibeli dengan ETH
 */
contract ShopItems is ERC1155, Ownable {

    // ============ ITEM IDS ============

    uint256 public constant SEED = 0;
    uint256 public constant FERTILIZER = 1;
    uint256 public constant WATER_CAN = 2;
    uint256 public constant PESTICIDE = 3;
    uint256 public constant GOLDEN_SHOVEL = 4;  // Rare item!

    // ============ STATE ============

    /**
     * @dev Item prices in wei
     */
    mapping(uint256 => uint256) public itemPrice;

    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public maxSupply;

    // ============ EVENTS ============

    event ItemPurchased(
        address indexed buyer,
        uint256 indexed itemId,
        uint256 amount,
        uint256 totalCost
    );

    // ============ CONSTRUCTOR ============

    constructor()
        ERC1155("https://liskgarden.example/api/item/{id}.json")
        Ownable(msg.sender)
    {
        // Set prices (in wei)
        itemPrice[SEED] = 0.0001 ether;
        itemPrice[FERTILIZER] = 0.0002 ether;
        itemPrice[WATER_CAN] = 0.0005 ether;
        itemPrice[PESTICIDE] = 0.0003 ether;
        itemPrice[GOLDEN_SHOVEL] = 0.01 ether;  // Expensive!

        // Set max supplies
        maxSupply[SEED] = 0;              // Unlimited
        maxSupply[FERTILIZER] = 0;        // Unlimited
        maxSupply[WATER_CAN] = 0;         // Unlimited
        maxSupply[PESTICIDE] = 0;         // Unlimited
        maxSupply[GOLDEN_SHOVEL] = 1000;  // Limited!
    }

    // ============ BUY FUNCTIONS ============

    /**
     * @dev Buy single item type
     */
    function buyItem(uint256 id, uint256 amount) external payable {
        uint256 cost = itemPrice[id] * amount;
        require(msg.value >= cost, "Insufficient payment");

        // Check max supply
        if (maxSupply[id] > 0) {
            require(
                totalSupply[id] + amount <= maxSupply[id],
                "Exceeds max supply"
            );
        }

        // Mint item
        _mint(msg.sender, id, amount, "");
        totalSupply[id] += amount;

        // Refund excess payment
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit ItemPurchased(msg.sender, id, amount, cost);
    }

    /**
     * @dev Buy batch items (1 transaction!)
     */
    function buyBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external payable {
        require(ids.length == amounts.length, "Length mismatch");

        // Calculate total cost
        uint256 totalCost = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            totalCost += itemPrice[ids[i]] * amounts[i];

            // Check max supply
            if (maxSupply[ids[i]] > 0) {
                require(
                    totalSupply[ids[i]] + amounts[i] <= maxSupply[ids[i]],
                    "Exceeds max supply"
                );
            }

            totalSupply[ids[i]] += amounts[i];
        }

        require(msg.value >= totalCost, "Insufficient payment");

        // Mint batch
        _mintBatch(msg.sender, ids, amounts, "");

        // Refund excess
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @dev Update item price
     */
    function setItemPrice(uint256 id, uint256 price) external onlyOwner {
        itemPrice[id] = price;
    }

    /**
     * @dev Withdraw contract balance
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}