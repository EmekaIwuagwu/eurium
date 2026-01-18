// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IEurium {
    function mint(address to, uint256 amount) external;
}

/**
 * @title ReserveManager
 * @dev Manages mint authorizations and custodian details with institutional controls.
 * @custom:security-contact security@eurium.io
 */
contract ReserveManager is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IEurium public eurium;

    struct Custodian {
        string name;
        address wallet;
        bool active;
        uint256 addedAt;
    }

    Custodian[] public custodians;

    mapping(bytes32 => bool) public mintAuthorizations;
    mapping(bytes32 => uint256) public mintTimestamps;

    // Daily mint limit (1 million EUI)
    uint256 public dailyMintLimit = 1_000_000 * 10 ** 18;
    uint256 public lastMintReset;
    uint256 public dailyMintedAmount;

    event MintAuthorized(
        bytes32 indexed authId,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );
    event CustodianAdded(
        uint256 indexed custodianId,
        string name,
        address indexed wallet
    );
    event CustodianUpdated(uint256 indexed custodianId, bool active);
    event DailyMintLimitUpdated(uint256 oldLimit, uint256 newLimit);

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Address cannot be zero");
        _;
    }

    constructor(
        address _eurium,
        address admin
    ) validAddress(_eurium) validAddress(admin) {
        eurium = IEurium(_eurium);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        lastMintReset = block.timestamp;
    }

    /**
     * @dev Adds a new custodian to the system.
     */
    function addCustodian(
        string memory name,
        address wallet
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        validAddress(wallet)
        returns (uint256)
    {
        require(bytes(name).length > 0, "Name cannot be empty");

        uint256 custodianId = custodians.length;
        custodians.push(
            Custodian({
                name: name,
                wallet: wallet,
                active: true,
                addedAt: block.timestamp
            })
        );

        emit CustodianAdded(custodianId, name, wallet);
        return custodianId;
    }

    /**
     * @dev Updates custodian active status.
     */
    function updateCustodianStatus(
        uint256 custodianId,
        bool active
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(custodianId < custodians.length, "Invalid custodian ID");
        custodians[custodianId].active = active;
        emit CustodianUpdated(custodianId, active);
    }

    /**
     * @dev Returns the number of custodians.
     */
    function getCustodianCount() public view returns (uint256) {
        return custodians.length;
    }

    /**
     * @dev Checks and resets daily mint limit if needed.
     */
    function _checkAndResetDailyLimit() private {
        if (block.timestamp >= lastMintReset + 1 days) {
            dailyMintedAmount = 0;
            lastMintReset = block.timestamp;
        }
    }

    /**
     * @dev Authorizes and executes a mint operation with daily limits.
     */
    function authorizeAndMint(
        address to,
        uint256 amount,
        bytes32 authId
    )
        public
        onlyRole(MANAGER_ROLE)
        nonReentrant
        whenNotPaused
        validAddress(to)
    {
        require(amount > 0, "Amount must be greater than zero");
        require(!mintAuthorizations[authId], "Authorization already used");

        _checkAndResetDailyLimit();
        require(
            dailyMintedAmount + amount <= dailyMintLimit,
            "Exceeds daily mint limit"
        );

        mintAuthorizations[authId] = true;
        mintTimestamps[authId] = block.timestamp;
        dailyMintedAmount += amount;

        eurium.mint(to, amount);
        emit MintAuthorized(authId, to, amount, block.timestamp);
    }

    /**
     * @dev Updates the daily mint limit.
     */
    function setDailyMintLimit(
        uint256 newLimit
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newLimit > 0, "Limit must be greater than zero");
        uint256 oldLimit = dailyMintLimit;
        dailyMintLimit = newLimit;
        emit DailyMintLimitUpdated(oldLimit, newLimit);
    }

    /**
     * @dev Pauses all minting operations.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses minting operations.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Returns current daily minting status.
     */
    function getDailyMintStatus()
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
            dailyMintLimit,
            dailyMintedAmount,
            dailyMintLimit - dailyMintedAmount,
            lastMintReset + 1 days
        );
    }
}
