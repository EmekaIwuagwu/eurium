# Eurium (EUI) - Aptos Implementation

This folder contains the Aptos Move implementation of the Eurium stablecoin using the Fungible Asset standard.

## Features
- **Fungible Asset Standard**: Modern Aptos token standard (AIP-21).
- **Admin Controls**: Mint, burn, and pause functionality.
- **Redemption Logic**: Integrated redemption flow for institutional settlement.

## Prerequisites
- [Aptos CLI](https://aptos.dev/tools/aptos-cli)

## Compilation
```bash
aptos move compile --named-addresses eurium_addr=default
```

## Testing
```bash
aptos move test --named-addresses eurium_addr=default
```

## Deployment
```bash
aptos move publish --named-addresses eurium_addr=default
```

## Bridge Adapter Spec
For cross-chain transfers (Wormhole/Axelar), a dedicated adapter should:
1. Lock/Burn EUI on Aptos via the `EuriumInfo` burn_ref.
2. Emit a `CrossChainTransferEvent` with target chain and address.
3. Relayers pick up the event and mint on the target chain.
