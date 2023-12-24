// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Vault
 * @dev A contract that allows users to deposit and withdraw ERC20 tokens.
 * The contract is pausable, meaning the owner can pause and unpause token transfers.
 * It also implements reentrancy guard to prevent reentrancy attacks.
 */
contract Vault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // =============================================================
    //                          Errors
    // =============================================================
    error AmountNotEnough();
    error TokenNotWhitelisted();
    error InsufficientBalance();
    error InvalidTokenAddress();

    // =============================================================
    //                          Events
    // =============================================================
    event Deposit(
        address indexed depositor,
        address indexed token,
        uint256 amount
    );
    event Withdrawal(
        address indexed withdrawer,
        address indexed token,
        uint256 amount
    );
    event TokenWhitelist(address indexed token, bool value);

    // =============================================================
    //                   State Variables
    // =============================================================

    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => bool) public whitelistedTokens;

    /**
     * @dev Constructor function
     * @param _admin The address of the admin/owner of the contract
     */
    constructor(address _admin) Ownable(_admin) Pausable() ReentrancyGuard() {}

    /**
     * @dev Deposits ERC20 tokens into the contract
     * @param _token The address of the ERC20 token to deposit
     * @param _amount The amount of tokens to deposit
     */
    function deposit(
        address _token,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        if (_amount <= 0) revert AmountNotEnough();
        if (!whitelistedTokens[_token]) revert TokenNotWhitelisted();
        balances[msg.sender][_token] += _amount;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _token, _amount);
    }

    /**
     * @dev Withdraws ERC20 tokens from the contract
     * @param _token The address of the ERC20 token to withdraw
     * @param _amount The amount of tokens to withdraw
     */
    function withdraw(
        address _token,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        if (balances[msg.sender][_token] < _amount)
            revert InsufficientBalance();
        balances[msg.sender][_token] -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdrawal(msg.sender, _token, _amount);
    }

    /**
     * @dev Pauses token transfers
     * Only the owner/admin can call this function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses token transfers
     * Only the owner/admin can call this function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Whitelists or unwhitelists an ERC20 token
     * Only the owner/admin can call this function
     * @param _token The address of the ERC20 token to whitelist/unwhitelist
     * @param _value The boolean value indicating whether to whitelist or unwhitelist the token
     */
    function whitelistToken(address _token, bool _value) external onlyOwner {
        if (_token == address(0)) revert InvalidTokenAddress();
        whitelistedTokens[_token] = _value;
        emit TokenWhitelist(_token, _value);
    }
}
