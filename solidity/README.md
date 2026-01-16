# Eurium (EUI) Stablecoin - EVM Implementation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stability: Stable](https://img.shields.io/badge/Stability-Stable-green.svg)](#)

Eurium is an institutional-grade, Euro-pegged stablecoin built for the EVM ecosystem. It features multi-role governance, upgradeable infrastructure, and a dual-step redemption process designed for regulatory compliance.

## 🚀 Core Features

- **Euro Pegged**: Designed to maintain a 1:1 value ratio with the Euro.
- **UUPS Upgradeable**: Built on the Universal Upgradeable Proxy Standard (Proxy-Implementation pattern) for secure logic updates.
- **Advanced RBAC**: Granular permissioning with Admin, Minter, Pauser, Upgrader, and Auditor roles.
- **Compliant Redemption**: Two-step redemption process (Request -> Finalize) to allow for off-chain KYC/AML verification.
- **Proof of Reserves**: Dedicated hooks for on-chain Merkle root attestations of collateral.
- **Gasless Transactions**: Supports EIP-2612 (Permit) for gasless approvals.

## 📁 Repository Structure

```text
solidity/
├── contracts/          # Core smart contracts
│   ├── Eurium.sol      # Main EUI token (ERC20 + RBAC + UUPS)
│   ├── ReserveManager.sol # Orchestrates minting and custodian management
│   └── Treasury.sol    # Secure fund management and fee collection
├── scripts/            # Deployment and operational scripts
├── test/               # Comprehensive test suite (8+ passing tests)
├── security/           # Legal and security documentation
└── hardhat.config.ts   # Multi-network configuration (Sepolia, Polygon, etc.)
```

## 🛠️ Setup & Installation

### Prerequisites
- Node.js (v18+)
- npm or yarn

### Installation
```bash
npm install
```

### Environment Configuration
1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
2. Fill in your `PRIVATE_KEY` and RPC URLs in `.env`.

## 🧪 Testing

Run the full test suite to ensure contract integrity:
```bash
npx hardhat test
```
Current tests cover:
- Deployment & role assignment
- Minting & Burning (Restricted)
- Pause/Unpause mechanics
- Redemption lifecycle (Request -> Finalization)

## 🚀 Deployment

The deployment script handles the proxy initialization and grants standard roles to the `ReserveManager` and `Treasury`.

**To Sepolia (Standard Testnet):**
```bash
npx hardhat run scripts/deploy.ts --network sepolia
```

**To Polygon Amoy (Polygon Testnet):**
```bash
npx hardhat run scripts/deploy.ts --network polygonAmoy
```

## 🛡️ Security Architecture

- **Pause Mechanism**: In case of emergency, the `PAUSER_ROLE` can freeze all token transfers.
- **Role Isolation**: Minting is restricted to the `ReserveManager` to ensure institutional control.
- **Circuit Breakers**: Upgrades are handled via `UPGRADER_ROLE` and should be managed by a multi-sig wallet in production.
- **Reentrancy Protection**: All financial methods are protected by OpenZeppelin's `ReentrancyGuard`.

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
