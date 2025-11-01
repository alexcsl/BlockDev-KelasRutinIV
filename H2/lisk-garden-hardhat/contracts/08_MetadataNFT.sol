// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title MetadataNFT
 * @dev NFT dengan on-chain metadata
 */
contract MetadataNFT is ERC721 {

    uint256 private _nextTokenId;

    /**
     * @dev Metadata struct
     */
    struct TokenMetadata {
        string name;
        string description;
        uint8 rarity;  // 1-5
    }

    /**
     * @dev Mapping token ID ke metadata
     */
    mapping(uint256 => TokenMetadata) public tokenMetadata;

    // ============ EVENTS ============

    event NFTMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string name,
        uint8 rarity
    );

    // ============ CONSTRUCTOR ============

    constructor() ERC721("Metadata NFT", "MNFT") {}

    // ============ MINT FUNCTION ============

    /**
     * @dev Mint NFT dengan metadata
     */
    function mint(
        address to,
        string memory name,
        string memory description,
        uint8 rarity
    ) external returns (uint256) {
        require(to != address(0), "Invalid address");
        require(rarity >= 1 && rarity <= 5, "Rarity must be 1-5");
        require(bytes(name).length > 0, "Name required");

        // Mint NFT
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);

        // Set metadata
        tokenMetadata[tokenId] = TokenMetadata({
            name: name,
            description: description,
            rarity: rarity
        });

        // Emit event
        emit NFTMinted(tokenId, to, name, rarity);

        return tokenId;
    }

    /**
     * @dev Get metadata
     */
    function getMetadata(uint256 tokenId)
        external
        view
        returns (TokenMetadata memory)
    {
        require(ownerOf(tokenId) != address(0), "Token doesn't exist");
        return tokenMetadata[tokenId];
    }
}