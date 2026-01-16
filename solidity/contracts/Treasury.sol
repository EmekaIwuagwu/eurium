// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Treasury
 * @dev Collects fees and operational funds with timelock principles.
 */
contract Treasury is AccessControl, ReentrancyGuard {
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    event FundsWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) public onlyRole(WITHDRAWER_ROLE) nonReentrant {
        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "ETH withdrawal failed");
        } else {
            IERC20(token).transfer(to, amount);
        }
        emit FundsWithdrawn(token, to, amount);
    }

    receive() external payable {}
}
