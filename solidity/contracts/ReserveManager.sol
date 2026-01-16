// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IEurium {
    function mint(address to, uint256 amount) external;
}

/**
 * @title ReserveManager
 * @dev Manages mint authorizations and custodian details.
 */
contract ReserveManager is AccessControl, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IEurium public eurium;

    struct Custodian {
        string name;
        address wallet;
        bool active;
    }

    Custodian[] public custodians;

    mapping(bytes32 => bool) public mintAuthorizations;

    event MintAuthorized(
        bytes32 indexed authId,
        address indexed to,
        uint256 amount
    );
    event CustodianAdded(string name, address wallet);

    constructor(address _eurium, address admin) {
        eurium = IEurium(_eurium);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function addCustodian(
        string memory name,
        address wallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        custodians.push(Custodian(name, wallet, true));
        emit CustodianAdded(name, wallet);
    }

    function authorizeAndMint(
        address to,
        uint256 amount,
        bytes32 authId
    ) public onlyRole(MANAGER_ROLE) nonReentrant {
        require(!mintAuthorizations[authId], "Authorization already used");
        mintAuthorizations[authId] = true;

        eurium.mint(to, amount);
        emit MintAuthorized(authId, to, amount);
    }
}
