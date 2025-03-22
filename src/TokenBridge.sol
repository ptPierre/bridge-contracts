// src/TokenBridge.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenBridge is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Events
    event Deposit(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 nonce
    );

    event Distribution(
        address indexed token,
        address indexed to,
        uint256 amount,
        uint256 nonce
    );

    // New events for bridge & swap
    event SwapDeposit(
        address indexed sourceToken,
        address indexed targetToken,
        address indexed from,
        address to,
        uint256 sourceAmount,
        uint256 nonce
    );

    event SwapDistribution(
        address indexed sourceToken,
        address indexed targetToken,
        address indexed to,
        uint256 sourceAmount,
        uint256 targetAmount,
        uint256 nonce
    );

    // State variables
    uint256 private _nonce;
    mapping(address => bool) private _supportedTokens;
    // Track processed deposits to prevent double-processing
    mapping(uint256 => bool) private _processedDeposits;
    // Pause mechanism
    bool private _paused;
    
    // New state variables for bridge & swap
    // Maps source token -> target token -> rate (1 source token = X target tokens, multiplied by 10^18 for precision)
    mapping(address => mapping(address => uint256)) private _swapRates;

    // Modifiers
    modifier whenNotPaused() {
        require(!_paused, "Bridge: paused");
        _;
    }

    modifier onlyDistributor() {
        // In production, this would be a more sophisticated authorization system
        require(msg.sender == owner(), "Bridge: not distributor");
        _;
    }

    constructor() Ownable(msg.sender) {
        _nonce = 0;
        _paused = false;
    }

    /**
     * @dev Adds a token to the supported tokens list
     * @param token The token address to add
     */
    function addSupportedToken(address token) external onlyOwner {
        _supportedTokens[token] = true;
    }

    /**
     * @dev Removes a token from the supported tokens list
     * @param token The token address to remove
     */
    function removeSupportedToken(address token) external onlyOwner {
        _supportedTokens[token] = false;
    }

    /**
     * @dev Sets the swap rate between two tokens
     * @param sourceToken The source token address
     * @param targetToken The target token address
     * @param rate The exchange rate (1 source token = rate target tokens, multiplied by 10^18)
     */
    function setSwapRate(
        address sourceToken,
        address targetToken,
        uint256 rate
    ) external onlyOwner {
        require(_supportedTokens[sourceToken], "Bridge: source token not supported");
        require(_supportedTokens[targetToken], "Bridge: target token not supported");
        require(rate > 0, "Bridge: rate must be greater than 0");
        
        _swapRates[sourceToken][targetToken] = rate;
    }
    
    /**
     * @dev Gets the swap rate between two tokens
     * @param sourceToken The source token address
     * @param targetToken The target token address
     * @return The exchange rate
     */
    function getSwapRate(
        address sourceToken,
        address targetToken
    ) external view returns (uint256) {
        return _swapRates[sourceToken][targetToken];
    }

    /**
     * @dev Pauses the bridge
     */
    function pause() external onlyOwner {
        _paused = true;
    }

    /**
     * @dev Unpauses the bridge
     */
    function unpause() external onlyOwner {
        _paused = false;
    }

    /**
     * @dev Deposits tokens to the bridge
     * @param token The token address
     * @param amount The amount to deposit
     * @param recipient The address that will receive tokens on the other chain
     */
    function deposit(
        address token,
        uint256 amount,
        address recipient
    ) external nonReentrant whenNotPaused {
        require(_supportedTokens[token], "Bridge: token not supported");
        require(amount > 0, "Bridge: amount must be greater than 0");
        
        // Transfer tokens from sender to bridge
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Emit deposit event
        uint256 currentNonce = _nonce++;
        emit Deposit(token, msg.sender, recipient, amount, currentNonce);
    }

    /**
     * @dev Deposits tokens for a cross-chain swap
     * @param sourceToken The token being deposited
     * @param targetToken The token to receive on the target chain
     * @param amount The amount to deposit
     * @param recipient The address that will receive tokens on the other chain
     */
    function depositForSwap(
        address sourceToken,
        address targetToken,
        uint256 amount,
        address recipient
    ) external nonReentrant whenNotPaused {
        require(_supportedTokens[sourceToken], "Bridge: source token not supported");
        require(_supportedTokens[targetToken], "Bridge: target token not supported");
        require(amount > 0, "Bridge: amount must be greater than 0");
        require(_swapRates[sourceToken][targetToken] > 0, "Bridge: swap pair not supported");
        
        // Transfer tokens from sender to bridge
        IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), amount);
        
        // Emit swap deposit event
        uint256 currentNonce = _nonce++;
        emit SwapDeposit(sourceToken, targetToken, msg.sender, recipient, amount, currentNonce);
    }

    /**
     * @dev Distributes tokens from the bridge to a recipient
     * @param token The token address
     * @param recipient The recipient address
     * @param amount The amount to distribute
     * @param depositNonce The nonce of the corresponding deposit
     */
    function distribute(
        address token,
        address recipient,
        uint256 amount,
        uint256 depositNonce
    ) external nonReentrant whenNotPaused onlyDistributor {
        require(_supportedTokens[token], "Bridge: token not supported");
        require(!_processedDeposits[depositNonce], "Bridge: deposit already processed");
        
        // Mark deposit as processed
        _processedDeposits[depositNonce] = true;
        
        // Transfer tokens from bridge to recipient
        IERC20(token).safeTransfer(recipient, amount);
        
        // Emit distribution event
        emit Distribution(token, recipient, amount, depositNonce);
    }

    /**
     * @dev Distributes swapped tokens from the bridge to a recipient
     * @param sourceToken The original token that was deposited
     * @param targetToken The token to distribute to the recipient
     * @param recipient The recipient address
     * @param sourceAmount The original amount that was deposited
     * @param depositNonce The nonce of the corresponding deposit
     */
    function distributeSwap(
        address sourceToken,
        address targetToken,
        address recipient,
        uint256 sourceAmount,
        uint256 depositNonce
    ) external nonReentrant whenNotPaused onlyDistributor {
        require(_supportedTokens[sourceToken], "Bridge: source token not supported");
        require(_supportedTokens[targetToken], "Bridge: target token not supported");
        require(!_processedDeposits[depositNonce], "Bridge: deposit already processed");
        
        // Calculate the target amount based on the swap rate
        uint256 rate = _swapRates[sourceToken][targetToken];
        require(rate > 0, "Bridge: swap pair not supported");
        
        // Calculate target amount (considering precision of 10^18 in rate)
        uint256 targetAmount = (sourceAmount * rate) / 1e18;
        
        // Mark deposit as processed
        _processedDeposits[depositNonce] = true;
        
        // Transfer swapped tokens from bridge to recipient
        IERC20(targetToken).safeTransfer(recipient, targetAmount);
        
        // Emit swap distribution event
        emit SwapDistribution(
            sourceToken,
            targetToken,
            recipient,
            sourceAmount,
            targetAmount,
            depositNonce
        );
    }

    /**
     * @dev Withdraws tokens in case of emergency
     * @param token The token address
     * @param amount The amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}