// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PlantNFTSkeleton
 * @dev Foundation untuk PlantNFT - akan dilengkapi di homework
 */
contract PlantNFTSkeleton is ERC721, Ownable {

    uint256 private _nextTokenId;

    // ============ PLANT METADATA ============

    struct PlantMetadata {
        string name;              // Nama tanaman
        string species;           // Jenis (Rose, Orchid, etc)
        uint256 plantedAt;        // Timestamp ditanam
        uint8 rarity;             // 1-5
        uint256 lastWatered;      // Timestamp terakhir disiram
        uint256 growthStage;      // 0=seed, 1=sprout, 2=growing, 3=mature
    }

    mapping(uint256 => PlantMetadata) public plants;

    /**
     * @dev Game contract yang boleh interact
     */
    address public gameContract;

    // ============ EVENTS ============

    event PlantMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string species,
        uint8 rarity
    );

    event PlantWatered(uint256 indexed tokenId, uint256 timestamp);

    event PlantGrown(uint256 indexed tokenId, uint256 newStage);

    // ============ MODIFIERS ============

    modifier onlyGameContract() {
        require(msg.sender == gameContract, "Only game contract");
        _;
    }

    // ============ CONSTRUCTOR ============

    constructor() ERC721("Lisk Garden Plant", "PLANT") Ownable(msg.sender) {}

    // ============ ADMIN FUNCTIONS ============

    function setGameContract(address _gameContract) external onlyOwner {
        require(_gameContract != address(0), "Invalid address");
        gameContract = _gameContract;
    }

    // ============ MINT FUNCTION ============

    /**
     * @dev Mint plant NFT
     * TODO: Add minting cost (HOMEWORK!)
     * TODO: Add rarity probability (HOMEWORK!)
     */
    function mintPlant(
        address to,
        string memory name,
        string memory species,
        uint8 rarity
    ) external returns (uint256) {
        require(to != address(0), "Invalid address");
        require(rarity >= 1 && rarity <= 5, "Invalid rarity");

        // TODO: Require payment (ETH or GardenToken)
        // TODO: Calculate rarity based on random

        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);

        plants[tokenId] = PlantMetadata({
            name: name,
            species: species,
            plantedAt: block.timestamp,
            rarity: rarity,
            lastWatered: block.timestamp,
            growthStage: 0  // Start as seed
        });

        emit PlantMinted(tokenId, to, species, rarity);

        return tokenId;
    }

    // ============ GAME FUNCTIONS ============

    /**
     * @dev Water plant
     * TODO: Add water cooldown (HOMEWORK!)
     * TODO: Add boost items integration (HOMEWORK!)
     */
    function waterPlant(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        // TODO: Check cooldown (ex: 1 water per day)
        // TODO: Check if plant needs water

        plants[tokenId].lastWatered = block.timestamp;

        emit PlantWatered(tokenId, block.timestamp);

        // TODO: Maybe trigger growth (HOMEWORK!)
    }

    /**
     * @dev Grow plant to next stage
     * TODO: Add growth requirements (HOMEWORK!)
     * TODO: Add time-based growth (HOMEWORK!)
     */
    function growPlant(uint256 tokenId) external onlyGameContract {
        require(plants[tokenId].growthStage < 3, "Already mature");

        // TODO: Check growth requirements:
        // - Time since planted
        // - Number of waterings
        // - Used fertilizer items?

        plants[tokenId].growthStage++;

        emit PlantGrown(tokenId, plants[tokenId].growthStage);
    }

    // ============ VIEW FUNCTIONS ============

    function getPlant(uint256 tokenId)
        external
        view
        returns (PlantMetadata memory)
    {
        require(ownerOf(tokenId) != address(0), "Token doesn't exist");
        return plants[tokenId];
    }

    /**
     * @dev Get all plants owned by address
     * TODO: Optimize for large collections (HOMEWORK!)
     */
    function getPlantsOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
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