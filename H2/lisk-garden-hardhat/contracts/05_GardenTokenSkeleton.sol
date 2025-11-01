// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title GardenTokenSkeleton
 * @dev Foundation untuk GardenToken - akan dilengkapi di homework
 */
contract GardenTokenSkeleton {

    // ============ METADATA ============

    string public constant NAME = "Garden Token";
    string public constant SYMBOL = "GDN";
    uint8 public constant DECIMALS = 18;

    // ============ STATE ============

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;

    address public owner;

    /**
     * @dev Game contract address (yang boleh mint rewards)
     */
    address public gameContract;

    /**
     * @dev Paused state (untuk emergency)
     */
    bool public paused;

    // ============ EVENTS ============

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event GameContractSet(address indexed gameContract);
    event Paused(address account);
    event Unpaused(address account);

    // ============ MODIFIERS ============

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyGameContract() {
        require(msg.sender == gameContract, "Only game contract");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // ============ CONSTRUCTOR ============

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        paused = false;

        // Mint initial supply to owner
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @dev Set game contract address
     * Hanya game contract yang boleh mint rewards
     */
    function setGameContract(address _gameContract) external onlyOwner {
        require(_gameContract != address(0), "Invalid address");
        gameContract = _gameContract;
        emit GameContractSet(_gameContract);
    }

    /**
     * @dev Pause contract (emergency)
     */
    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpause contract
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // ============ VIEW FUNCTIONS ============

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    // ============ TRANSFER FUNCTIONS ============

    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(to != address(0), "Invalid recipient");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        require(spender != address(0), "Invalid spender");

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        require(to != address(0), "Invalid recipient");

        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    // ============ MINT & BURN ============

    /**
     * @dev Mint rewards (hanya game contract)
     * TODO: Implement reward calculation logic (HOMEWORK!)
     */
    function mintReward(address to, uint256 amount) external onlyGameContract whenNotPaused {
        require(to != address(0), "Invalid recipient");

        // TODO: Add reward calculation logic here
        // TODO: Add max supply check
        // TODO: Add daily mint limit

        balances[to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Burn tokens
     * TODO: Implement burn requirements (HOMEWORK!)
     */
    function burn(uint256 amount) public whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // TODO: Add burn cooldown
        // TODO: Add minimum burn amount
        // TODO: Track total burned for analytics

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }
}