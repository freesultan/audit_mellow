## Test 
```
forge test --fork-url $(grep ETH_RPC .env | cut -d '=' -f2,3,4,5) --gas-limit 10000000000000000 --fork-block-number 22730425 -vvv

```
or use vm.warp (block.timestamp + 5000)

flexible-vaults/test/integration/BaseIntegrationTest.sol

## Ideas
- focus on logic errors and data validations
- 
### 1
 
 monitor all accounts in a vault (all queues of all assets)
 call claimshare for the lowset balance accounts where shares is near 0
 or call claimshare for his own addresses with very low balance near 0 

 or front run users redeem request and call claimshares from sharemodule/claim from depositQueue for that account,
### 2 


## checklist
### Signature validation
- 
- 
### oracle security 
- 
- 
- 
### logic error
- 
-
### data validation
## 
- every queue is for one asset
- every queue is owned by one `vault`
