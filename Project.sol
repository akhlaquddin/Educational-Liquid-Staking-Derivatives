// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title EduStake
 * @dev Implementation of liquid staking derivatives for educational initiatives
 */
contract EduStake is ERC20, Ownable, ReentrancyGuard, Pausable {
    // State variables
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakingTimestamp;
    uint256 public totalStaked;
    uint256 public constant MINIMUM_STAKE = 0.1 ether;
    uint256 public constant LOCK_PERIOD = 30 days;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 amount);
    event EducationalProjectFunded(address indexed project, uint256 amount);

    constructor() ERC20("Education Staking Token", "EDU") Ownable(msg.sender) {
    }

    /**
     * @dev Stake ETH and receive EDU tokens
     */
    function stake() external payable nonReentrant whenNotPaused {
        require(msg.value >= MINIMUM_STAKE, "Stake amount too low");
        
        uint256 tokensToMint = calculateTokenAmount(msg.value);
        stakedBalance[msg.sender] += msg.value;
        stakingTimestamp[msg.sender] = block.timestamp;
        totalStaked += msg.value;
        
        _mint(msg.sender, tokensToMint);
        
        emit Staked(msg.sender, msg.value);
    }

    /**
     * @dev Unstake ETH by burning EDU tokens
     * @param amount Amount of tokens to burn
     */
    function unstake(uint256 amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(block.timestamp >= stakingTimestamp[msg.sender] + LOCK_PERIOD, "Lock period not ended");
        
        uint256 ethToReturn = calculateEthAmount(amount);
        require(address(this).balance >= ethToReturn, "Insufficient contract balance");
        
        stakedBalance[msg.sender] -= ethToReturn;
        totalStaked -= ethToReturn;
        _burn(msg.sender, amount);
        
        (bool success, ) = payable(msg.sender).call{value: ethToReturn}("");
        require(success, "ETH transfer failed");
        
        emit Unstaked(msg.sender, ethToReturn);
    }

    /**
     * @dev Fund educational project
     * @param project Address of educational project
     * @param amount Amount to fund
     */
    function fundEducationalProject(address project, uint256 amount) external onlyOwner {
        require(project != address(0), "Invalid project address");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        (bool success, ) = payable(project).call{value: amount}("");
        require(success, "Funding transfer failed");
        
        emit EducationalProjectFunded(project, amount);
    }

    /**
     * @dev Distribute staking rewards
     */
    function distributeRewards() external payable onlyOwner {
        require(msg.value > 0, "Must send rewards");
        require(totalStaked > 0, "No stakers");
        
        emit RewardsDistributed(msg.value);
    }

    /**
     * @dev Calculate token amount for given ETH amount
     * @param ethAmount Amount of ETH
     * @return Token amount
     */
    function calculateTokenAmount(uint256 ethAmount) public pure returns (uint256) {
        return ethAmount; // 1:1 ratio for simplicity
    }

    /**
     * @dev Calculate ETH amount for given token amount
     * @param tokenAmount Amount of tokens
     * @return ETH amount
     */
    function calculateEthAmount(uint256 tokenAmount) public pure returns (uint256) {
        return tokenAmount; // 1:1 ratio for simplicity
    }

    /**
     * @dev Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {}
}