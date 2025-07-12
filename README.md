# Mellow Flexible Vaults  contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the **Issues** page in your private contest repo (label issues as **Medium** or **High**)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
Ethereum, Arbitrum, Base, Hyperliquid L1, Avalanche, Berachain, BSC, OP Mainnet, Polygon, Sonic, Unichain 
___

### Q: If you are integrating tokens, are you allowing only whitelisted tokens to work with the codebase or any complying with the standard? Are they assumed to have certain properties, e.g. be non-reentrant? Are there any types of [weird tokens](https://github.com/d-xo/weird-erc20) you want to integrate?
Only whitelisted assets are supported in the system: standard ERC20 tokens, native tokens and stETH.
___

### Q: Are there any limitations on values set by admins (or other roles) in the codebase, including restrictions on array lengths?
The following roles are considered trusted. This means entities assigned to these roles are assumed to act in accordance with protocol safety assumptions, and all values they set are expected to be within safe, bounded, and reviewable ranges.

trusted roles:
# role / most preferred holder type or contract
1. owner in all contracts (including openzeppelin-contracts/contracts/proxy/transparent
/ProxyAdmin.sol) (admin, proxy-admin)
2. Consensus:signer (admin)
3. DEFAULT_ADMIN_ROLE (admin)
4. keccak256("managers.ShareManager.SET_FLAGS_ROLE") (admin)
5. keccak256("managers.ShareManager.SET_ACCOUNT_INFO_ROLE") (admin)
6. keccak256("managers.RiskManager.SET_VAULT_LIMIT_ROLE") (admin)
7. keccak256("managers.RiskManager.SET_SUBVAULT_LIMIT_ROLE") (admin)
8. keccak256("managers.RiskManager.ALLOW_SUBVAULT_ASSETS_ROLE") (admin)
9. keccak256("managers.RiskManager.DISALLOW_SUBVAULT_ASSETS_ROLE") (admin)
10. keccak256("managers.RiskManager.MODIFY_SUBVAULT_BALANCE_ROLE") (admin)
11. keccak256("managers.RiskManager.MODIFY_PENDING_ASSETS_ROLE") (queues)
12. keccak256("managers.RiskManager.MODIFY_VAULT_BALANCE_ROLE") (queues, admin)
13. keccak256("managers.RiskManager.MODIFY_SUBVAULT_BALANCE_ROLE") (Vault.sol, admin)
14. keccak256("modules.ShareModule.SET_HOOK_ROLE") (admin)
15. keccak256("modules.ShareModule.CREATE_DEPOSIT_QUEUE_ROLE") (admin)
16. keccak256("modules.ShareModule.CREATE_REDEEM_QUEUE_ROLE") (admin)
17. keccak256("modules.ShareModule.PAUSE_QUEUE_ROLE") (admin)
18. keccak256("modules.ShareModule.UNPAUSE_QUEUE_ROLE") (admin)
19. keccak256("modules.ShareModule.SET_QUEUE_LIMIT_ROLE") (admin)
20. keccak256("modules.ShareModule.REMOVE_QUEUE_ROLE") (admin)
21. keccak256("modules.VaultModule.CREATE_SUBVAULT_ROLE") (admin)
22. keccak256("modules.VaultModule.DISCONNECT_SUBVAULT_ROLE") (admin)
23. keccak256("modules.VaultModule.RECONNECT_SUBVAULT_ROLE") (admin)
24. keccak256("modules.VaultModule.PULL_LIQUIDITY_ROLE") (admin)
25. keccak256("modules.VaultModule.PUSH_LIQUIDITY_ROLE") (admin)
26. keccak256("oracles.Oracle.SUBMIT_REPORTS_ROLE") (operator)
27. keccak256("oracles.Oracle.ACCEPT_REPORT_ROLE") (admin)
28. keccak256("oracles.Oracle.SET_SECURITY_PARAMS_ROLE") (admin)
29. keccak256("oracles.Oracle.ADD_SUPPORTED_ASSETS_ROLE") (admin)
30. keccak256("oracles.Oracle.REMOVE_SUPPORTED_ASSETS_ROLE") (admin)
31. keccak256("permissions.protocols.SymbioticVerifier.CALLER_ROLE") (operator)
32. keccak256("permissions.protocols.SymbioticVerifier.MELLOW_VAULT_ROLE") (Subvault.sol)
33. keccak256("permissions.protocols.SymbioticVerifier.SYMBIOTIC_FARM_ROLE") (symbiotic: DefaultStakerRewards.sol)
34. keccak256("permissions.protocols.SymbioticVerifier.SYMBIOTIC_VAULT_ROLE") (symbiotic: Vault.sol)
35. keccak256("permissions.protocols.EigenLayerVerifier.ASSET_ROLE") (vault asset)
36. keccak256("permissions.protocols.EigenLayerVerifier.CALLER_ROLE") (operator)
37. keccak256("permissions.protocols.EigenLayerVerifier.MELLOW_VAULT_ROLE") (Subvault.sol)
38. keccak256("permissions.protocols.EigenLayerVerifier.OPERATOR_ROLE") (EigenLayer: operator)
39. keccak256("permissions.protocols.EigenLayerVerifier.RECEIVER_ROLE") (Subvault.sol)
40. keccak256("permissions.protocols.EigenLayerVerifier.STRATEGY_ROLE") (EigenLayer: strategy)
41. keccak256("permissions.protocols.ERC20Verifier.ASSET_ROLE") (vault asset)
42. keccak256("permissions.protocols.ERC20Verifier.CALLER_ROLE") (operator)
43. keccak256("permissions.protocols.ERC20Verifier.RECIPIENT_ROLE") (external contract)
44. keccak256("permissions.Verifier.SET_MERKLE_ROOT_ROLE") (admin)
45. keccak256("permissions.Verifier.CALLER_ROLE") (operator)
46. keccak256("permissions.Verifier.ALLOW_CALL_ROLE") (admin)
47. keccak256("permissions.Verifier.DISALLOW_CALL_ROLE") (admin)

Additional assumptions:
1. No unbounded arrays or arbitrarily large input values will be accepted. All input parameters are constrained to prevent out-of-gas (OOG) conditions during execution.
2. Lockup durations, Oracle timeouts, and other time-sensitive configuration values will be set within non-griefable and operationally safe bounds.
3. Total fee rates configured in the system (e.g., performance + protocol + deposit + redeem fees) will always remain well below 25%.
4. `queueLimit` value will be configured such that no single operation risks exceeding the block gas limit, even under worst-case execution paths.
5. While not enforced at the contract level, the total number of subvaults per MultiVault is assumed to remain under 100.
6. Only implementations explicitly included within this scope will be deployed through Factory contracts.
7. Only hooks explicitly included within this scope will be used in the system.
8. Only queues explicitly included within this scope will be used in the system.
9. Only vault configurations (Vault.sol and Subvault.sol) explicitly included within this scope will be used in the system.

___

### Q: Are there any limitations on values set by admins (or other roles) in protocols you integrate with, including restrictions on array lengths?
No
___

### Q: Is the codebase expected to comply with any specific EIPs?
No
___

### Q: Are there any off-chain mechanisms involved in the protocol (e.g., keeper bots, arbitrage bots, etc.)? We assume these mechanisms will not misbehave, delay, or go offline unless otherwise specified.
1. Off-chain Oracle bot: a dedicated off-chain bot is responsible for periodically collecting LP token prices and submitting them as part of Oracle reports.
2. Flashbots Usage: flashbots or other private transaction relays may be used to execute actions performed by trusted actors (e.g., admins, operators), especially when timing, frontrunning protection, or MEV resistance is critical.


___

### Q: What properties/invariants do you want to hold even if breaking them has a low/unknown impact?
No
___

### Q: Please discuss any design choices you made.
1. Permissioned Signature Queues and Off-chain Pricing. The system uses permissioned signature queues in which the actual deposit or redemption price is determined off-chain by a consensus group of signers. While these prices are protected by default oracle checks, any findings that assume a malicious consensus group (i.e., colluding signers submitting manipulated prices) are considered out of scope and will be invalidated.

2. stETH–ETH Price Assumption. The system assumes stETH and ETH have equal value for the purpose of all calculations and accounting. Therefore, any findings or attacks relying on deviations between stETH and ETH prices will be considered invalid.

3. Oracle Role and Trusted Price Reports. The Oracle serves as the external entry point for price updates into the vault system. We assume all submitted Oracle reports are accurate and manipulation-resistant. However, in the rare case that a legitimate price deviation (e.g., due to a slashing event in a Symbiotic vault) triggers out-of-bounds conditions defined in the securityParameters, an `admin` is expected to adjust the security parameters (e.g., raise max deviation boundaries) prior to report submission, ensuring the updated report can be accepted.
___

### Q: Please provide links to previous audits (if any) and all the known issues or acceptable risks.
No
___

### Q: Please list any relevant protocol resources.
TBD
___

### Q: Additional audit information.
No


# Audit scope

[flexible-vaults @ 08ff5756c61a9828f758fb7e34a52efc89daea18](https://github.com/mellow-finance/flexible-vaults/tree/08ff5756c61a9828f758fb7e34a52efc89daea18)
- [flexible-vaults/src/factories/Factory.sol](flexible-vaults/src/factories/Factory.sol)
- [flexible-vaults/src/hooks/BasicRedeemHook.sol](flexible-vaults/src/hooks/BasicRedeemHook.sol)
- [flexible-vaults/src/hooks/LidoDepositHook.sol](flexible-vaults/src/hooks/LidoDepositHook.sol)
- [flexible-vaults/src/hooks/RedirectingDepositHook.sol](flexible-vaults/src/hooks/RedirectingDepositHook.sol)
- [flexible-vaults/src/libraries/FenwickTreeLibrary.sol](flexible-vaults/src/libraries/FenwickTreeLibrary.sol)
- [flexible-vaults/src/libraries/ShareManagerFlagLibrary.sol](flexible-vaults/src/libraries/ShareManagerFlagLibrary.sol)
- [flexible-vaults/src/libraries/SlotLibrary.sol](flexible-vaults/src/libraries/SlotLibrary.sol)
- [flexible-vaults/src/libraries/TransferLibrary.sol](flexible-vaults/src/libraries/TransferLibrary.sol)
- [flexible-vaults/src/managers/BasicShareManager.sol](flexible-vaults/src/managers/BasicShareManager.sol)
- [flexible-vaults/src/managers/FeeManager.sol](flexible-vaults/src/managers/FeeManager.sol)
- [flexible-vaults/src/managers/RiskManager.sol](flexible-vaults/src/managers/RiskManager.sol)
- [flexible-vaults/src/managers/ShareManager.sol](flexible-vaults/src/managers/ShareManager.sol)
- [flexible-vaults/src/managers/TokenizedShareManager.sol](flexible-vaults/src/managers/TokenizedShareManager.sol)
- [flexible-vaults/src/modules/ACLModule.sol](flexible-vaults/src/modules/ACLModule.sol)
- [flexible-vaults/src/modules/BaseModule.sol](flexible-vaults/src/modules/BaseModule.sol)
- [flexible-vaults/src/modules/CallModule.sol](flexible-vaults/src/modules/CallModule.sol)
- [flexible-vaults/src/modules/ShareModule.sol](flexible-vaults/src/modules/ShareModule.sol)
- [flexible-vaults/src/modules/SubvaultModule.sol](flexible-vaults/src/modules/SubvaultModule.sol)
- [flexible-vaults/src/modules/VaultModule.sol](flexible-vaults/src/modules/VaultModule.sol)
- [flexible-vaults/src/modules/VerifierModule.sol](flexible-vaults/src/modules/VerifierModule.sol)
- [flexible-vaults/src/oracles/Oracle.sol](flexible-vaults/src/oracles/Oracle.sol)
- [flexible-vaults/src/permissions/BitmaskVerifier.sol](flexible-vaults/src/permissions/BitmaskVerifier.sol)
- [flexible-vaults/src/permissions/Consensus.sol](flexible-vaults/src/permissions/Consensus.sol)
- [flexible-vaults/src/permissions/MellowACL.sol](flexible-vaults/src/permissions/MellowACL.sol)
- [flexible-vaults/src/permissions/Verifier.sol](flexible-vaults/src/permissions/Verifier.sol)
- [flexible-vaults/src/permissions/protocols/ERC20Verifier.sol](flexible-vaults/src/permissions/protocols/ERC20Verifier.sol)
- [flexible-vaults/src/permissions/protocols/EigenLayerVerifier.sol](flexible-vaults/src/permissions/protocols/EigenLayerVerifier.sol)
- [flexible-vaults/src/permissions/protocols/OwnedCustomVerifier.sol](flexible-vaults/src/permissions/protocols/OwnedCustomVerifier.sol)
- [flexible-vaults/src/permissions/protocols/SymbioticVerifier.sol](flexible-vaults/src/permissions/protocols/SymbioticVerifier.sol)
- [flexible-vaults/src/queues/DepositQueue.sol](flexible-vaults/src/queues/DepositQueue.sol)
- [flexible-vaults/src/queues/Queue.sol](flexible-vaults/src/queues/Queue.sol)
- [flexible-vaults/src/queues/RedeemQueue.sol](flexible-vaults/src/queues/RedeemQueue.sol)
- [flexible-vaults/src/queues/SignatureDepositQueue.sol](flexible-vaults/src/queues/SignatureDepositQueue.sol)
- [flexible-vaults/src/queues/SignatureQueue.sol](flexible-vaults/src/queues/SignatureQueue.sol)
- [flexible-vaults/src/queues/SignatureRedeemQueue.sol](flexible-vaults/src/queues/SignatureRedeemQueue.sol)
- [flexible-vaults/src/vaults/Subvault.sol](flexible-vaults/src/vaults/Subvault.sol)
- [flexible-vaults/src/vaults/Vault.sol](flexible-vaults/src/vaults/Vault.sol)
- [flexible-vaults/src/vaults/VaultConfigurator.sol](flexible-vaults/src/vaults/VaultConfigurator.sol)


