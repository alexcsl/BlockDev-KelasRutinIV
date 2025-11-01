// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title MintableToken
 * @dev ERC-20 dengan kemampuan mint & burn
 */
contract MintableToken {

    // ============ METADATA ============

    string public name;
    string public symbol;
    uint8 public decimals;

    // ============ STATE ============

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;

    /**
     * @dev Owner contract (yang deploy)
     */
    address public owner;

    // ============ EVENTS ============

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ============ MODIFIERS ============

    /**
     * @dev Modifier untuk restrict akses hanya owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    // ============ CONSTRUCTOR ============

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender; // Set owner

        // Mint initial supply
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    // ============ VIEW FUNCTIONS ============

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    // ============ TRANSFER FUNCTIONS ============

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Cannot transfer to zero address");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Cannot approve zero address");
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_to != address(0), "Cannot transfer to zero address");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // ============ MINT & BURN ============

    /**
     * @dev Mint token baru ke address tertentu
     * @param _to Address recipient
     * @param _amount Jumlah token yang di-mint
     *
     * Hanya owner yang bisa mint!
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");

        // Tambah balance recipient
        balances[_to] += _amount;

        // Tambah total supply
        totalSupply += _amount;

        // Emit Transfer dari address(0) = minting
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev Burn (hancurkan) token caller
     * @param _amount Jumlah token yang di-burn
     *
     * Siapa saja bisa burn token sendiri
     */
    function burn(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance to burn");

        // Kurangi balance caller
        balances[msg.sender] -= _amount;

        // Kurangi total supply
        totalSupply -= _amount;

        // Emit Transfer ke address(0) = burning
        emit Transfer(msg.sender, address(0), _amount);
    }
}