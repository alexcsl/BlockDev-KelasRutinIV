// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title BasicMultiToken
 * @dev ERC-1155 paling sederhana
 */
contract BasicMultiToken is ERC1155 {

    uint256 public nextTokenId;

    /**
     * @dev Constructor dengan base URI
     * URI format: https://game.example/api/item/{id}.json
     */
    constructor() ERC1155("https://game.example/api/item/{id}.json") {}

    /**
     * @dev Mint token baru
     * @param to Recipient
     * @param amount Jumlah token
     */
    function mint(
        address to,
        uint256 amount
    ) external returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId, amount, "");
        return tokenId;
    }
}