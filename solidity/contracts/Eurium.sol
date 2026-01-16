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
        uint256 timestamp;
    }

    mapping(bytes32 => RedemptionRequest) public redemptions;

    // Reserve Proof Hooks
    bytes32 public currentReserveRoot;
    uint256 public lastReserveUpdate;

    event RedemptionRequested(
        address indexed requester,
        uint256 amount,
        string redemptionId,
        bytes32 internalId
    );
    event RedemptionCompleted(bytes32 indexed internalId, string redemptionId);
    event ReserveUpdated(bytes32 newRoot, uint256 timestamp);

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

    function snapshot() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Initiate a redemption request. EUI is transferred to this contract until finalized.
     */
    function redeemRequest(
        uint256 amount,
        string memory redemptionId
    ) public whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        bytes32 internalId = keccak256(
            abi.encodePacked(msg.sender, amount, redemptionId, block.timestamp)
        );

        _transfer(msg.sender, address(this), amount);

        redemptions[internalId] = RedemptionRequest({
            requester: msg.sender,
            amount: amount,
            redemptionId: redemptionId,
            completed: false,
            timestamp: block.timestamp
        });

        emit RedemptionRequested(msg.sender, amount, redemptionId, internalId);
    }

    /**
     * @dev Finalize a burn after off-chain KYC/settlement.
     */
    function finalizeRedemption(
        bytes32 internalId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        RedemptionRequest storage request = redemptions[internalId];
        require(!request.completed, "Redemption already completed");
        require(request.amount > 0, "Redemption does not exist");

        request.completed = true;
        _burn(address(this), request.amount);

        emit RedemptionCompleted(internalId, request.redemptionId);
    }

    /**
     * @dev Update on-chain reserve proof attestation.
     */
    function updateReserveProof(bytes32 newRoot) public onlyRole(AUDITOR_ROLE) {
        currentReserveRoot = newRoot;
        lastReserveUpdate = block.timestamp;
        emit ReserveUpdated(newRoot, block.timestamp);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

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
