// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract BasicToken {
    // Map address to balance
    mapping(address => uint256) public balances;

    // TOtal supply
    uint256 public totalSupply;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Constructor
    constructor(uint256 _initialSupply){
        // Semua token ke creator
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;

        // Emit transfer
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    // Public FUnctions
    function transfer(address _to, uint256 _value) public returns(bool success) {
        // 1. Validasi, Enough balance?
        require(balances[msg.sender] >= _value, "Insufficient Balance");

        //2. Validasi, Recipient Valid? 
        require(_to != address(0), "Cannot transfer to 0 address");

        // 3. Update Balance
        balances[msg.sender] -= _value; // Kurangin sender
        balances[_to] += _value; // Tambahin si recipient

        // 4. Emit event
        emit Transfer(msg.sender, _to, _value);

        // 5. Return success
        return true;
    }

    // Get balance
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}