// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract LearnNumber {
    uint256 public plantId;
    uint256 public waterLevel;

    constructor(){
        plantId = 1;
        waterLevel = 100;
    }
    
    function changePlantId(uint256 _newId) public {
        plantId = _newId;
    }

    function addWater() public {
        waterLevel += 10;
    }



}