// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title SimpleNFT
 * @dev NFT menggunakan OpenZeppelin ERC721
 */
contract SimpleNFT is ERC721 {

    uint256 private _nextTokenId;

    /**
     * @dev Constructor set name & symbol
     */
    constructor() ERC721("Simple NFT", "SNFT") {}

    /**
     * @dev Mint NFT (anyone can mint)
     */
    function mint(address to) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        return tokenId;
    }
}