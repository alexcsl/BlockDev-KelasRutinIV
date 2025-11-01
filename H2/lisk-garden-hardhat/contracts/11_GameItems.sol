// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GameItems
 * @dev ERC-1155 untuk game items dengan pre-defined types
 */
contract GameItemsss is ERC1155, Ownable {

    // ============ ITEM IDS (Constants) ============

    uint256 public constant WOODEN_SWORD = 0;
    uint256 public constant STEEL_SWORD = 1;
    uint256 public constant LEGENDARY_SWORD = 2;
    uint256 public constant HEALTH_POTION = 3;
    uint256 public constant MANA_POTION = 4;

    // ============ STATE ============
//
    /**
     * @dev Track total minted per item
     */
    mapping(uint256 => uint256) public totalSupply;

    /**
     * @dev Max supply per item (0 = unlimited)
     */
    mapping(uint256 => uint256) public maxSupply;

    // ============ EVENTS ============

    event ItemMinted(
        address indexed to,
        uint256 indexed id,
        uint256 amount
    );

    // ============ CONSTRUCTOR ============

    constructor()
        ERC1155("https://liskgarden.example/api/item/{id}.json")
        Ownable(msg.sender)
    {
        // Set max supplies
        maxSupply[WOODEN_SWORD] = 0;           // Unlimited
        maxSupply[STEEL_SWORD] = 0;            // Unlimited
        maxSupply[LEGENDARY_SWORD] = 100;      // Limited!
        maxSupply[HEALTH_POTION] = 0;          // Unlimited
        maxSupply[MANA_POTION] = 0;            // Unlimited
    }

    // ============ MINT FUNCTIONS ============

    /**
     * @dev Mint specific item
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        // Check max supply
        if (maxSupply[id] > 0) {
            require(
                totalSupply[id] + amount <= maxSupply[id],
                "Exceeds max supply"
            );
        }

        // Mint
        _mint(to, id, amount, "");

        // Update total supply
        totalSupply[id] += amount;

        emit ItemMinted(to, id, amount);
    }

    /**
     * @dev Mint batch items
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        // Check all supplies
        for (uint256 i = 0; i < ids.length; i++) {
            if (maxSupply[ids[i]] > 0) {
                require(
                    totalSupply[ids[i]] + amounts[i] <= maxSupply[ids[i]],
                    "Exceeds max supply"
                );
            }
            totalSupply[ids[i]] += amounts[i];
        }

        _mintBatch(to, ids, amounts, "");
    }

    // ============ UTILITY FUNCTIONS ============

    /**
     * @dev Get item name (for frontend)
     */
    function getItemName(uint256 id) public pure returns (string memory) {
        if (id == WOODEN_SWORD) return "Wooden Sword";
        if (id == STEEL_SWORD) return "Steel Sword";
        if (id == LEGENDARY_SWORD) return "Legendary Sword";
        if (id == HEALTH_POTION) return "Health Potion";
        if (id == MANA_POTION) return "Mana Potion";
        return "Unknown Item";
    }
}