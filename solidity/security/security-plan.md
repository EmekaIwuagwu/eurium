# Eurium Security Infrastructure

## Threat Model

### Assets
1. **EUI Token Ledger**: Authenticity of balances and total supply.
2. **Minting Authority**: Privilege to create new tokens.
3. **Upgradeability Path**: Control over the smart contract logic.
4. **Reserve Root**: Integrity of on-chain proof-of-reserves.

### Threats & Mitigations

| Threat | Description | Mitigation |
| :--- | :--- | :--- |
| **Admin Key Compromise** | Attacker steals admin private keys. | Multisig (Gnosis Safe) with 3/5 or 5/7 threshold. |
| **Minting Inflation** | Unauthorized EUI minting. | `ReserveManager` logic, off-chain multisig sign-off, volume limits. |
| **Upgrade Hijack** | Malicious implementation upgrade. | Upgrader role on timelocked multisig; logic audit on every upgrade. |
| **Oracle Manipulation** | Peg monitoring failure. | Multi-source oracles (Chainlink + Pyth) with circuit breakers. |
| **Reentrancy** | Drain during redemption. | `nonReentrant` modifiers and CEI pattern. |

## Bug Bounty Program (Draft)

### Scope
- `Eurium.sol`
- `ReserveManager.sol`
- `Treasury.sol`

### Reward Tiers
- **Critical (Up to $50,000)**: Theft of funds, unauthorized minting, permanent bricking of contract.
- **High ($10,000)**: Circumventing PAUSER_ROLE, unauthorized upgrade.
- **Medium ($2,500)**: Griefing redemptions, incorrect reserve proof updates.
- **Low ($500)**: Logic errors with minimal financial impact.

## Emergency Response Runbook
1. **Identify**: Monitor Slack/PagerDuty alerts for peg deviation or suspicious mints.
2. **Freeze**: Use `PAUSER_ROLE` to call `pause()` immediately.
3. **Analyze**: Auditor role analyzes state; verify event logs.
4. **Remediate**: Deploy fix implementation if needed via `UPGRADER_ROLE`.
5. **Resume**: `unpause()` after fix verification and community notice.
