// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Interface for PlantNFT integration
interface IPlantNFT {
    function getPlant(uint256 tokenId) external view returns (
        uint256 id,
        uint8 growthStage,
        address owner,
        uint8 rarity,
        uint256 plantedDate,
        uint256 lastWatered,
        bool isAlive,
        bool harvested
    );
}

contract GardenToken{
    // disini kita masukin meta datanya

    string public constant NAME = "Garden Token";
    string public constant SYMBOL = "GDN";
    uint8 public constant DECIMALS = 18;


    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;


    address public owner;
    address public gameContract;
    address public plantNFTAddress;
    IPlantNFT public plantNFT;
    bool public paused;


    // SUPPLY MANAGEMENT
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 **18;

    // REWARD SYSTEM
    mapping(uint256 => uint256) public dailyMintedAmount;
    uint256 public constant MAX_DAILY_MINT = 10_000 * 10**18;


    // BURN MECHANISM
    uint256 public totalBurned;
    mapping(address => uint256) public lastBurnTime;
    uint256 public constant BURN_COOLDOWN = 1 days;




    // kita buat events yang akan terjadi
    event Transfer(address indexed from , address indexed to, uint256 value);
    event Approval(address indexed from , address indexed spender , uint256 value);
    event GameContractSet(address indexed gameContract);
    event PlantNFTSet(address indexed plantNFT);
    event Paused(address account);
    event UnPaused(address account);
    event RewardMinted(address indexed player, uint256 amount, uint8 rarity, uint256 stage);
    event TokensBurned(address indexed burner, uint256 amount, uint256 totalBurned);
    event DailyMintLimitReached(uint256 day, uint256 amount);


    // disini kita buat function untuk pengubahan
    modifier onlyOwner(){
        require(msg.sender == owner , "Only Owner");
        _;
    }

    modifier onlyGameContract(){
        require(msg.sender == gameContract , "Only game contract");
        _;
    }

    modifier whenNotPaused(){
        require(!paused, "Contract is paused");
        _;
    }

    //constructor buat initialize awal2

    constructor(uint256 _initTotalSupply){
        owner = msg.sender;
        paused = false;

        balances[msg.sender] = _initTotalSupply;
        totalSupply = _initTotalSupply;

        emit Transfer(address(0), msg.sender, _initTotalSupply);
    }

    // Admin function 

    function setGameContract(address _gameContract) external onlyOwner{
        require(_gameContract != address(0), "Invalid address");
        gameContract = _gameContract;
        emit GameContractSet(_gameContract);
    }
    
    function setPlantNFT(address _plantNFTAddress) external onlyOwner {
        require(_plantNFTAddress != address(0), "Invalid address");
        plantNFTAddress = _plantNFTAddress;
        plantNFT = IPlantNFT(_plantNFTAddress);
        emit PlantNFTSet(_plantNFTAddress);
    }

    function pause() external onlyOwner(){
        paused = true;
        emit Paused(msg.sender);
    }
    function unpause() external onlyOwner(){
        paused = false;
        emit UnPaused(msg.sender);
    }

    // kita tambahkan view functions nya
    function name() public pure returns (string memory){
        return NAME;
    }

    function symbol() public pure returns (string memory){
        return SYMBOL;
    }

    function decimals() public pure returns (uint8){
        return DECIMALS;
    }

    function balanceOf(address account) public view returns(uint256){
        return balances[account];
    }

    function allowance(address _owner , address _spender) public view returns(uint256){
        return allowances[_owner][_spender];
    }

    function circulatingSupply() public view returns (uint256){
        return totalSupply - balances[address(this)];
    }
    
    function burnRate() public view returns (uint256) {
        if (totalSupply == 0) return 0;
        // Return burn rate as percentage with 2 decimal places (basis points)
        // totalBurned / (totalSupply + totalBurned) * 10000
        uint256 totalEverMinted = totalSupply + totalBurned;
        return (totalBurned * 10000) / totalEverMinted;
    }





    // transfer function for the coins

    function transfer(address _to , uint256 _amount) public whenNotPaused() returns (bool){
        require(balances[msg.sender] >= _amount , "Insufficient balance");
        require(_to != address(0), "Invalid recipient");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 amount) public whenNotPaused() returns (bool){
        require(_spender != address(0) , "Invalid spender" );

        allowances[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);


        return true;
    }


    function transferFrom(address _from , address _to , uint256 _value) public whenNotPaused() returns (bool){
        require(balances[_from] >= _value , "Insufficient balance" );
        require(allowances[_from][msg.sender] >= _value , "Insufficient allowances");
        require(_to != address(0) , "Invalid recipient");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    // REWARD SYSTEM
    /**
     * Calculate reward based on plant rarity & growth stage
     *
     * Formula:
     * Base reward = 10 GDN
     * Rarity multiplier:
     *   - Common (1): 1x
     *   - Rare (2): 2x
     *   - Epic (3): 3x
     *   - Legendary (4): 5x
     *   - Mythic (5): 10x
     * Growth stage multiplier:
     *   - Seed (0): 0x (no reward)
     *   - Sprout (1): 0.5x
     *   - Growing (2): 0.75x
     *   - Mature (3): 1x
     */
    function calculateReward(uint8 rarity, uint256 growthStage)
        public
        pure
        returns (uint256)
    {
        // No reward for seed stage
        if (growthStage == 0) {
            return 0;
        }
        
        uint256 baseReward = 10 * 10**18; // 10 GDN base
        
        // Rarity multiplier
        uint256 rarityMultiplier;
        if (rarity == 1) {
            rarityMultiplier = 1; // Common
        } else if (rarity == 2) {
            rarityMultiplier = 2; // Rare
        } else if (rarity == 3) {
            rarityMultiplier = 3; // Epic
        } else if (rarity == 4) {
            rarityMultiplier = 5; // Legendary
        } else if (rarity == 5) {
            rarityMultiplier = 10; // Mythic
        } else {
            rarityMultiplier = 1; // Default to Common
        }
        
        // Growth stage multiplier
        uint256 stageMultiplier;
        if (growthStage == 1) {
            stageMultiplier = 50; // 0.5x (50/100)
        } else if (growthStage == 2) {
            stageMultiplier = 75; // 0.75x (75/100)
        } else if (growthStage == 3) {
            stageMultiplier = 100; // 1x (100/100)
        } else {
            stageMultiplier = 100; // Default to 1x
        }
        
        return (baseReward * rarityMultiplier * stageMultiplier) / 100;
    }
    
    // Internal function to get plant data and calculate reward
    function _calculatePlantReward(uint256 plantId) internal view returns(uint256){
        require(plantNFTAddress != address(0), "PlantNFT not set");
        
        // Get plant data from NFT contract
        (
            ,
            uint8 growthStage,
            ,
            uint8 rarity,
            ,
            ,
            bool isAlive,
            bool harvested
        ) = plantNFT.getPlant(plantId);
        
        require(isAlive, "Plant is dead");
        require(!harvested, "Already harvested");
        
        return calculateReward(rarity, growthStage);
    }
    // MINT & BURN

    function mintReward(address to, uint256 amount) external onlyGameContract whenNotPaused {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        
        // Check max supply
        require(totalSupply + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        // Check daily mint limit
        uint256 today = block.timestamp / 1 days;
        require(dailyMintedAmount[today] + amount <= MAX_DAILY_MINT, "Exceeds daily mint limit");

        // Update daily minted amount
        dailyMintedAmount[today] += amount;
        
        // Check if daily limit reached
        if (dailyMintedAmount[today] == MAX_DAILY_MINT) {
            emit DailyMintLimitReached(today, MAX_DAILY_MINT);
        }
        
        // Mint tokens
        balances[to] += amount;
        totalSupply += amount;
        
        emit Transfer(address(0), to, amount);
    }
    
    // Function to mint reward for specific plant (using internal calculation)
    function mintPlantReward(address to, uint256 plantId, uint8 rarity, uint256 growthStage) external onlyGameContract whenNotPaused {
        require(to != address(0), "Invalid recipient");
        
        uint256 rewardAmount = calculateReward(rarity, growthStage);
        require(rewardAmount > 0, "No reward for this plant");
        
        // Check max supply
        require(totalSupply + rewardAmount <= MAX_SUPPLY, "Exceeds max supply");
        
        // Check daily mint limit
        uint256 today = block.timestamp / 1 days;
        require(dailyMintedAmount[today] + rewardAmount <= MAX_DAILY_MINT, "Exceeds daily mint limit");

        // Update daily minted amount
        dailyMintedAmount[today] += rewardAmount;
        
        // Mint tokens
        balances[to] += rewardAmount;
        totalSupply += rewardAmount;
        
        emit Transfer(address(0), to, rewardAmount);
        emit RewardMinted(to, rewardAmount, rarity, growthStage);
    }
    
    // Alternative mint function for fixed amounts (admin use)
    function mintTokens(address _to, uint256 _amount) external onlyOwner() whenNotPaused(){
        require(_to != address(0), "Invalid recipient");
        require(totalSupply + _amount <= MAX_SUPPLY, "Exceeds max supply");
        
        balances[_to] += _amount;
        totalSupply += _amount;
        
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * Burn cooldown: 1 day per user
     * Minimum burn: 10 GDN
     * Track total burned for analytics
     */
    function burn(uint256 amount) public whenNotPaused {
        uint256 minBurnAmount = 10 * 10**18; // 10 GDN minimum
        
        require(amount >= minBurnAmount, "Minimum burn amount is 10 GDN");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(block.timestamp >= lastBurnTime[msg.sender] + BURN_COOLDOWN, "Burn cooldown active");

        balances[msg.sender] -= amount;
        totalSupply -= amount;
        totalBurned += amount;
        lastBurnTime[msg.sender] = block.timestamp;
        
        emit Transfer(msg.sender, address(0), amount);
        emit TokensBurned(msg.sender, amount, totalBurned);
    }
    
    // Keep existing burnTokens for backward compatibility
    function burnTokens(uint256 _amount) external whenNotPaused(){
        burn(_amount);
    }
    
    // Emergency burn by owner (no cooldown)
    function emergencyBurn(address _from, uint256 _amount) external onlyOwner(){
        require(balances[_from] >= _amount, "Insufficient balance");
        
        balances[_from] -= _amount;
        totalSupply -= _amount;
        totalBurned += _amount;
        
        emit Transfer(_from, address(0), _amount);
        emit TokensBurned(_from, _amount, totalBurned);
    }
    
    // ANALYTICS & VIEW FUNCTIONS
    
    function getDailyMintedAmount(uint256 day) external view returns (uint256) {
        return dailyMintedAmount[day];
    }
    
    function getCurrentDayMintedAmount() external view returns (uint256) {
        uint256 today = block.timestamp / 1 days;
        return dailyMintedAmount[today];
    }
    
    function getRemainingDailyMint() external view returns (uint256) {
        uint256 today = block.timestamp / 1 days;
        uint256 minted = dailyMintedAmount[today];
        return minted >= MAX_DAILY_MINT ? 0 : MAX_DAILY_MINT - minted;
    }
    
    function canBurn(address user) external view returns (bool) {
        return block.timestamp >= lastBurnTime[user] + BURN_COOLDOWN;
    }
    
    function getTimeUntilBurn(address user) external view returns (uint256) {
        uint256 nextBurnTime = lastBurnTime[user] + BURN_COOLDOWN;
        return nextBurnTime > block.timestamp ? nextBurnTime - block.timestamp : 0;
    }
    
    function getTokenomics() external view returns (
        uint256 _totalSupply,
        uint256 _maxSupply,
        uint256 _totalBurned,
        uint256 _circulatingSupply,
        uint256 _treasuryBalance
    ) {
        return (
            totalSupply,
            MAX_SUPPLY,
            totalBurned,
            circulatingSupply(),
            balances[address(this)]
        );
    }




}
