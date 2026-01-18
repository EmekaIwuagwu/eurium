# Eurium (EUI) - Euro-Pegged Stablecoin

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Deployed on Sepolia](https://img.shields.io/badge/Deployed-Sepolia-blue.svg)](#live-deployments)

Eurium is an institutional-grade, Euro-pegged stablecoin ecosystem with dual-chain support for **EVM** (Ethereum, Polygon) and **Aptos** networks.

## 🌟 Overview

This repository contains the complete implementation of the Eurium stablecoin protocol:
- **`solidity/`**: EVM-compatible smart contracts (Ethereum, Polygon, etc.)
- **`aptos/`**: Aptos Move implementation

## 🚀 Key Features

- **Multi-Chain**: Native support for EVM and Aptos ecosystems
- **Institutional Grade**: UUPS upgradeable with advanced RBAC
- **Regulatory Compliant**: Two-step redemption with KYC/AML hooks
- **Proof of Reserves**: On-chain Merkle root attestations
- **Battle-Tested**: Comprehensive test coverage with 8+ passing tests

## 📦 Quick Start

### Solidity (EVM)
```bash
cd solidity
npm install
npx hardhat test
```

### Aptos (Move)
```bash
cd aptos
aptos move test
```

## 🌐 Live Deployments

### Sepolia Testnet (Ethereum)
- **Eurium (EUI)**: [`0xcEeee392B3666327cca7e0dF7BbF1387719795e5`](https://sepolia.etherscan.io/address/0xcEeee392B3666327cca7e0dF7BbF1387719795e5)
- **ReserveManager**: [`0x64C0d2C5d88a42db716Ee3860bECE2400b485a87`](https://sepolia.etherscan.io/address/0x64C0d2C5d88a42db716Ee3860bECE2400b485a87)
- **Treasury**: [`0x2661c2A4841975166CEC9bAdAEE3F9C71Df41Dab`](https://sepolia.etherscan.io/address/0x2661c2A4841975166CEC9bAdAEE3F9C71Df41Dab)

### Polygon Amoy Testnet
- **Eurium (EUI)**: [`0x79fc40161D49B88Ae8658D3E16fb085aC7208220`](https://amoy.polygonscan.com/address/0x79fc40161D49B88Ae8658D3E16fb085aC7208220)
- **ReserveManager**: [`0xdDC7a84B617E6a08934e7c93B677a30DC8890fff`](https://amoy.polygonscan.com/address/0xdDC7a84B617E6a08934e7c93B677a30DC8890fff)
- **Treasury**: [`0xe0572C001B320dBd214C5ddB592C018FA5cedA4F`](https://amoy.polygonscan.com/address/0xe0572C001B320dBd214C5ddB592C018FA5cedA4F)

## 📖 Documentation

- [Solidity Documentation](./solidity/README.md)
- [Aptos Documentation](./aptos/README.md)
- [Security Plan](./solidity/security/security-plan.md)
- [Legal Checklist](./solidity/security/legal-checklist.md)

## 🛡️ Security

All contracts have been built with security best practices:
- OpenZeppelin battle-tested libraries
- Reentrancy guards on all financial operations
- Role-based access control
- Emergency pause mechanisms

## 📄 License
MIT License - see [LICENSE](LICENSE) for details.

---

**Developed with ❤️ for institutional DeFi**
