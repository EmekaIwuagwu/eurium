// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Eurium
 * @dev Euro-pegged stablecoin (EUI) with institutional-grade controls.
 * @custom:security-contact security@eurium.io
 */
contract Eurium is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    ERC20SnapshotUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    // Redemption tracking
    struct RedemptionRequest {
        address requester;
        uint256 amount;
        string redemptionId;
        bool completed;
        bool cancelled;
        uint256 timestamp;
    }

    mapping(bytes32 => RedemptionRequest) public redemptions;

    // Reserve Proof Hooks
    bytes32 public currentReserveRoot;
    uint256 public lastReserveUpdate;

    // Supply cap for security (10 billion tokens)
    uint256 public constant MAX_SUPPLY = 10_000_000_000 * 10 ** 18;

    event RedemptionRequested(
        address indexed requester,
        uint256 amount,
        string redemptionId,
        bytes32 indexed internalId
    );
    event RedemptionCompleted(bytes32 indexed internalId, string redemptionId);
    event RedemptionCancelled(bytes32 indexed internalId, string redemptionId);
    event ReserveUpdated(bytes32 indexed newRoot, uint256 timestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address defaultAdmin,
        address pauser,
        address minter,
        address upgrader,
        address auditor
    ) public initializer {
        require(defaultAdmin != address(0), "Admin cannot be zero address");
        require(pauser != address(0), "Pauser cannot be zero address");
        require(minter != address(0), "Minter cannot be zero address");
        require(upgrader != address(0), "Upgrader cannot be zero address");
        require(auditor != address(0), "Auditor cannot be zero address");

        __ERC20_init("Eurium", "EUI");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("Eurium");
        __ERC20Snapshot_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(UPGRADER_ROLE, upgrader);
        _grantRole(AUDITOR_ROLE, auditor);
    }

    /**
     * @dev Returns the number of decimals used for token amounts.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev Creates a snapshot of the current token state.
     */
    function snapshot() public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return _snapshot();
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Mints new tokens. Enforces supply cap.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds maximum supply");
        _mint(to, amount);
    }

    /**
     * @dev Initiate a redemption request. EUI is transferred to this contract until finalized.
     */
    function redeemRequest(
        uint256 amount,
        string memory redemptionId
    ) public whenNotPaused nonReentrant returns (bytes32) {
        require(amount > 0, "Amount must be greater than zero");
        require(
            bytes(redemptionId).length > 0,
            "Redemption ID cannot be empty"
        );

        bytes32 internalId = keccak256(
            abi.encodePacked(msg.sender, amount, redemptionId, block.timestamp)
        );
        require(
            redemptions[internalId].amount == 0,
            "Redemption ID already exists"
        );

        _transfer(msg.sender, address(this), amount);

        redemptions[internalId] = RedemptionRequest({
            requester: msg.sender,
            amount: amount,
            redemptionId: redemptionId,
            completed: false,
            cancelled: false,
            timestamp: block.timestamp
        });

        emit RedemptionRequested(msg.sender, amount, redemptionId, internalId);
        return internalId;
    }

    /**
     * @dev Allows users to cancel their pending redemption requests.
     */
    function cancelRedemption(bytes32 internalId) public nonReentrant {
        RedemptionRequest storage request = redemptions[internalId];
        require(request.requester == msg.sender, "Not the requester");
        require(!request.completed, "Redemption already completed");
        require(!request.cancelled, "Redemption already cancelled");
        require(request.amount > 0, "Redemption does not exist");

        request.cancelled = true;
        _transfer(address(this), msg.sender, request.amount);

        emit RedemptionCancelled(internalId, request.redemptionId);
    }

    /**
     * @dev Finalize a burn after off-chain KYC/settlement.
     */
    function finalizeRedemption(
        bytes32 internalId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        RedemptionRequest storage request = redemptions[internalId];
        require(!request.completed, "Redemption already completed");
        require(!request.cancelled, "Redemption was cancelled");
        require(request.amount > 0, "Redemption does not exist");

        request.completed = true;
        _burn(address(this), request.amount);

        emit RedemptionCompleted(internalId, request.redemptionId);
    }

    /**
     * @dev Update on-chain reserve proof attestation.
     */
    function updateReserveProof(bytes32 newRoot) public onlyRole(AUDITOR_ROLE) {
        require(newRoot != bytes32(0), "Reserve root cannot be zero");
        currentReserveRoot = newRoot;
        lastReserveUpdate = block.timestamp;
        emit ReserveUpdated(newRoot, block.timestamp);
    }

    /**
     * @dev Returns the current snapshot ID.
     */
    function getCurrentSnapshotId() public view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        require(
            newImplementation != address(0),
            "Invalid implementation address"
        );
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(
            ERC20Upgradeable,
            ERC20PausableUpgradeable,
            ERC20SnapshotUpgradeable
        )
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
