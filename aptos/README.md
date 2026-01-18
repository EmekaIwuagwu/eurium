# Eurium (EUI) - Aptos Implementation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stability: Production Ready](https://img.shields.io/badge/Stability-Production_Ready-green.svg)](#)

This folder contains the Aptos Move implementation of the Eurium stablecoin using the **Fungible Asset (FA)** standard (AIP-21).

## 🚀 Features
- **Fungible Asset Standard**: Built on the modern Aptos FA standard for maximum efficiency and interoperability.
- **Institutional Controls**: Integrated Mint, Burn, and Pause refs with role-based access.
- **High Performance**: sub-second finality and high throughput on Aptos.
- **Redemption Hooks**: Integrated structures for institutional redemption settlemennt.
- **Metadata Management**: On-chain metadata (EUI symbol, decimals, logo).

## 📁 Structure
- `sources/eurium.move`: Core module logic.
- `Move.toml`: Package configuration and dependencies.
- `tests/`: Move unit tests.

## 🛠️ Compilation & Testing

### Compilation
```bash
aptos move compile --named-addresses eurium_addr=default
```

### Testing
```bash
aptos move test --named-addresses eurium_addr=default
```

## 🚀 Deployment

### Live Testnet Deployment (v1.0.0)

| Contract / Address | Value |
|-------------------|-------|
| **Module Address** | `0x696403f92b301f0a19abac3e8e94081022e624696bfbf3228fdc3b1bd24ec88c` |
| **Module ID** | `eurium` |
| **Network** | Aptos Testnet |
| **Explorer** | [View on Aptos Explorer](https://explorer.aptoslabs.com/account/0x696403f92b301f0a19abac3e8e94081022e624696bfbf3228fdc3b1bd24ec88c?network=testnet) |

### Deployment Transactions
- **Publish**: [0x2142b441bf896cb5f620074a88ead9fa0852615092645910823ee2633537ed85](https://explorer.aptoslabs.com/txn/0x2142b441bf896cb5f620074a88ead9fa0852615092645910823ee2633537ed85?network=testnet)
- **Initialize**: [0x92c1943af2fb56f6a3142075c41d160ddd504a8285e31f055d8b2c954fb4badd](https://explorer.aptoslabs.com/txn/0x92c1943af2fb56f6a3142075c41d160ddd504a8285e31f055d8b2c954fb4badd?network=testnet)

## 📖 Key Functions

- **`initialize(admin: &signer)`**: Sets up the EUI fungible asset and metadata.
- **`mint(admin: &signer, to: address, amount: u64)`**: Authorized minting of EUI tokens.
- **`burn(admin: &signer, from: address, amount: u64)`**: Authorized burning of EUI tokens.
- **`set_pause(admin: &signer, paused: bool)`**: Pauses all EUI operations in emergencies.

## 🔄 Version History
- **v1.0.0** (Jan 18, 2026) - Initial Aptos Testnet deployment with Fungible Asset standard.

---

**Developed for institutional DeFi on Aptos**
