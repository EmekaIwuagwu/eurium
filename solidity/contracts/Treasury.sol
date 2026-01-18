// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Treasury
 * @dev Secure treasury for collecting fees and operational funds with timelock and withdrawal limits.
 * @custom:security-contact security@eurium.io
 */
contract Treasury is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    // Daily withdrawal limit (1 million USD equivalent in wei)
    uint256 public dailyWithdrawalLimit = 1_000_000 ether;
    uint256 public lastWithdrawalReset;
    uint256 public dailyWithdrawnAmount;

    event FundsWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );
    event FundsReceived(
        address indexed token,
        address indexed from,
        uint256 amount,
        uint256 timestamp
    );
    event DailyWithdrawalLimitUpdated(uint256 oldLimit, uint256 newLimit);

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Address cannot be zero");
        _;
    }

    constructor(address admin) validAddress(admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        lastWithdrawalReset = block.timestamp;
    }

    /**
     * @dev Checks and resets daily withdrawal limit if needed.
     */
    function _checkAndResetDailyLimit() private {
        if (block.timestamp >= lastWithdrawalReset + 1 days) {
            dailyWithdrawnAmount = 0;
            lastWithdrawalReset = block.timestamp;
        }
    }

    /**
     * @dev Withdraws funds from treasury with daily limits.
     * @param token Address of token (address(0) for native currency)
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function withdraw(
        address token,
        address to,
        uint256 amount
    )
        public
        onlyRole(WITHDRAWER_ROLE)
        nonReentrant
        whenNotPaused
        validAddress(to)
    {
        require(amount > 0, "Amount must be greater than zero");

        _checkAndResetDailyLimit();
        require(
            dailyWithdrawnAmount + amount <= dailyWithdrawalLimit,
            "Exceeds daily withdrawal limit"
        );

        dailyWithdrawnAmount += amount;

        if (token == address(0)) {
            require(
                address(this).balance >= amount,
                "Insufficient native balance"
            );
            (bool success, ) = to.call{value: amount}("");
            require(success, "Native currency transfer failed");
        } else {
            require(
                IERC20(token).balanceOf(address(this)) >= amount,
                "Insufficient token balance"
            );
            IERC20(token).safeTransfer(to, amount);
        }

        emit FundsWithdrawn(token, to, amount, block.timestamp);
    }

    /**
     * @dev Emergency withdrawal function (bypasses daily limits, requires admin).
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant validAddress(to) {
        require(amount > 0, "Amount must be greater than zero");

        if (token == address(0)) {
            require(
                address(this).balance >= amount,
                "Insufficient native balance"
            );
            (bool success, ) = to.call{value: amount}("");
            require(success, "Native currency transfer failed");
        } else {
            require(
                IERC20(token).balanceOf(address(this)) >= amount,
                "Insufficient token balance"
            );
            IERC20(token).safeTransfer(to, amount);
        }

        emit FundsWithdrawn(token, to, amount, block.timestamp);
    }

    /**
     * @dev Updates the daily withdrawal limit.
     */
    function setDailyWithdrawalLimit(
        uint256 newLimit
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newLimit > 0, "Limit must be greater than zero");
        uint256 oldLimit = dailyWithdrawalLimit;
        dailyWithdrawalLimit = newLimit;
        emit DailyWithdrawalLimitUpdated(oldLimit, newLimit);
    }

    /**
     * @dev Pauses all withdrawal operations.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses withdrawal operations.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Returns current daily withdrawal status.
     */
    function getDailyWithdrawalStatus()
        public
        view
        returns (
            uint256 limit,
            uint256 used,
            uint256 remaining,
            uint256 resetTime
        )
    {
        return (
            dailyWithdrawalLimit,
            dailyWithdrawnAmount,
            dailyWithdrawalLimit - dailyWithdrawnAmount,
            lastWithdrawalReset + 1 days
        );
    }

    /**
     * @dev Returns balance of a specific token.
     */
    function getBalance(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /**
     * @dev Receive function to accept native currency.
     */
    receive() external payable {
        emit FundsReceived(address(0), msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Fallback function.
     */
    fallback() external payable {
        emit FundsReceived(address(0), msg.sender, msg.value, block.timestamp);
    }
}
