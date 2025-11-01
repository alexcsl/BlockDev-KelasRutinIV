// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title BasicNFT
 * @dev NFT paling sederhana - mint & transfer saja
 */
contract BasicNFT {

    // ============ STATE VARIABLES ============

    /**
     * @dev Mapping dari token ID ke owner address
     */
    mapping(uint256 => address) public owners;

    /**
     * @dev Mapping dari owner address ke jumlah NFT
     */
    mapping(address => uint256) public balances;

    /**
     * @dev Counter untuk token ID berikutnya
     */
    uint256 public nextTokenId;

    // ============ EVENTS ============

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // ============ FUNCTIONS ============

    /**
     * @dev Mint NFT baru
     * @param to Recipient address
     * @return tokenId The ID of minted NFT
     */
    function mint(address to) external returns (uint256) {
        require(to != address(0), "Cannot mint to zero address");

        // Get next token ID
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        // Set owner
        owners[tokenId] = to;

        // Increase balance
        balances[to]++;

        // Emit transfer from address(0) = minting
        emit Transfer(address(0), to, tokenId);

        return tokenId;
    }

    /**
     * @dev Transfer NFT
     * @param to Recipient
     * @param tokenId NFT to transfer
     */
    function transfer(address to, uint256 tokenId) external {
        // Check ownership
        require(owners[tokenId] == msg.sender, "Not owner");
        require(to != address(0), "Cannot transfer to zero address");

        address from = msg.sender;

        // Update ownership
        owners[tokenId] = to;

        // Update balances
        balances[from]--;
        balances[to]++;

        // Emit event
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Get owner of token
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "Token doesn't exist");
        return owner;
    }

    /**
     * @dev Get balance of address
     */
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Invalid address");
        return balances[owner];
    }
}