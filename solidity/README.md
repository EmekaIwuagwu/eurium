# Eurium (EUI) - Euro-pegged Stablecoin

Institutional-grade, audited, and compliant Euro-pegged stablecoin.

## Features
- **ERC-20 & EIP-2612**: Full standard compliance with permit support for gasless approvals.
- **UUPS Upgradeable**: Secure upgrade path via the Universal Upgradeable Proxy Standard.
- **RBAC**: Multi-role access control (Admin, Minter, Pauser, Upgrader, Auditor).
- **Institutional Redemption**: On-chain redemption requests with multi-step finalization for KYC/AML compliance.
- **Reserve Proofs**: Hooks for on-chain Merkle root attestations of reserves.
- **Safety**: Circuit breakers, pause functionality, and reentrancy protection.

## Project Structure
- `contracts/`: Solidity smart contracts.
- `scripts/`: Deployment and operational scripts.
- `test/`: TypeScript unit and integration tests.
- `security/`: Threat models and security analysis.
- `ci/`: GitHub Actions pipelines.

## Installation
```bash
npm install
```

## Compilation
```bash
npx hardhat compile
```

## Testing
```bash
npx hardhat test
```

## Deployment
```bash
npx hardhat run scripts/deploy.ts --network <network_name>
```

## Security Design
- **Minting**: Strictly restricted to `MINTER_ROLE`. In production, this should be held by `ReserveManager`.
- **Pausing**: `PAUSER_ROLE` can freeze all transfers in case of emergency.
- **Upgrades**: Only `UPGRADER_ROLE` can upgrade implementation.
- **Auditing**: `AUDITOR_ROLE` can update reserve proofs.

## License
MIT
