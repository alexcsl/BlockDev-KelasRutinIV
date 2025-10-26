// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract LiskGarden {
    enum GrowthStage {SEED, SPROUT, GROWING, BLOOMING}

    // Struct 
    struct Plant {
        uint256 id;
        address owner;
        GrowthStage stage;
        uint256 plantedDate;
        uint256 lastWatered;    
        uint8 waterLevel;
        bool exists;
        bool isDead;   
    }
    // Mapping
    mapping(uint256 => Plant) public plants;
    mapping(address => uint256[]) public ownerPlants;

    // State
    uint256 public plantCounter;
    address public owner;

    // Constants
    uint256 public constant PLANT_PRICE = 0.001 ether;
    uint256 public constant HARVEST_REWARD = 0.003 ether;
    uint256 public constant STAGE_DURATION = 1 minutes;
    uint8 public constant WATER_DEPLETION_TIME = 30 seconds;
    uint8 public constant WATER_DEPLETION_RATE = 2;

    // Events
    event PlantSeeded(address indexed owner, uint256 indexed plantId);
    event PlantWatered(uint256 indexed plantId, uint8 newWaterLevel);
    event PlantHarvested(uint256 indexed plantId, address indexed owner, uint256 reward);
    event StageAdvanced(uint256 indexed plantId, GrowthStage newStage);
    event PlantDied(uint256 indexed plantId);

    // Functions & Constructors
    constructor() {
        // set owner? 
        owner = msg.sender;
        plantCounter = 0;
    }

    function plantSeed() external payable returns(uint256){
        // Make it require that the owner has enough money
        require(msg.value >= PLANT_PRICE, "Insufficient Money");
        plantCounter++;
        uint256 newId = plantCounter;
        Plant memory newPlant = Plant({
            id: newId,
            owner: msg.sender,
            stage: GrowthStage.SEED,
            plantedDate: block.timestamp,
            lastWatered: block.timestamp,
            waterLevel: 100,
            exists: true,
            isDead: false
        });

        plants[newId] = newPlant;
        ownerPlants[msg.sender].push(newId);
        emit PlantSeeded(msg.sender, newId);
        return newId;
    }

    function calculateWaterLevel(uint256 plantId) public view returns(uint8){
        Plant memory chosenPlant = plants[plantId];
        if(chosenPlant.isDead || !chosenPlant.exists){
            return 0;
        }

        uint256 timeSinceWatered = block.timestamp - chosenPlant.lastWatered;
        uint8 depletionIntervals = uint8(timeSinceWatered / WATER_DEPLETION_TIME);
        uint8 waterLost = depletionIntervals * WATER_DEPLETION_RATE;
        
        // If water lost is greater than the actual water level, it means that it has 0 water level (cant go negative)
        if(waterLost >= chosenPlant.waterLevel) return 0;
        return chosenPlant.waterLevel - waterLost;
    }

    function updateWaterLevel(uint256 plantId) internal {
        // Check the storage for the chosen plant
        Plant storage chosenPlant = plants[plantId];
        uint8 currentWater = calculateWaterLevel(plantId);
        chosenPlant.waterLevel = currentWater;

        if(currentWater == 0 && !chosenPlant.isDead){
            chosenPlant.isDead = true;
            emit PlantDied(plantId);
        }
    }

    function waterPlant(uint256 plantId) external {
        // Take plant from storage
        Plant storage chosenPlant = plants[plantId];
        require(chosenPlant.exists, "Plant does not exist");
        require(chosenPlant.owner == msg.sender, "You do not own the plant!");
        require(!chosenPlant.isDead, "Plant is dead");

        chosenPlant.waterLevel = 100;
        chosenPlant.lastWatered = block.timestamp;

        emit PlantWatered(plantId, 100);
        updatePlantStage(plantId);
    }

    function updatePlantStage(uint256 plantId) public {
        Plant storage chosenPlant = plants[plantId];
        require(chosenPlant.exists, "Plant does not exist");

        updateWaterLevel(plantId);
        if(chosenPlant.isDead) return;

        uint256 timeSincePlanted = block.timestamp - chosenPlant.plantedDate;
        GrowthStage oldStage = chosenPlant.stage;

        if(timeSincePlanted >= 3 * STAGE_DURATION){
            chosenPlant.stage = GrowthStage.BLOOMING;
        } else if(timeSincePlanted >= 2 * STAGE_DURATION){
            chosenPlant.stage = GrowthStage.GROWING;
        } else if(timeSincePlanted >= 1 * STAGE_DURATION){
            chosenPlant.stage = GrowthStage.SPROUT;
        } else {
            chosenPlant.stage = GrowthStage.SEED;
        }

        if(chosenPlant.stage != oldStage){
            emit StageAdvanced(plantId, chosenPlant.stage);
        }
    }

    function harvestPlant(uint256 plantId) external {
        Plant storage chosenPlant = plants[plantId];
        require(chosenPlant.exists, "Plant does not exist");
        require(chosenPlant.owner == msg.sender, "You do not own the plant!");
        require(!chosenPlant.isDead, "Plant is dead");

        updatePlantStage(plantId);
        require(chosenPlant.stage == GrowthStage.BLOOMING, "Not bloomed yet");

        chosenPlant.exists = false;

        emit PlantHarvested(plantId, msg.sender, HARVEST_REWARD);

        (bool success, ) = msg.sender.call{value: HARVEST_REWARD}("");
        require(success, "Transfer Failed");    
    }

    // Helper Functions
    function getPlant(uint256 plantId) external view returns (Plant memory){
        Plant memory chosenPlant = plants[plantId];
        chosenPlant.waterLevel = calculateWaterLevel(plantId);
        return chosenPlant;
    }

    function getUserPlants(address user) external view returns(uint256[] memory) {
        return ownerPlants[user];
    }

    function withdraw() external{
        require(msg.sender == owner, "Not the Owner");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "You Failed");
    }

    receive() external payable {}
    
}