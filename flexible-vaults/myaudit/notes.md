## Test 
```
forge test --fork-url $(grep ETH_RPC .env | cut -d '=' -f2,3,4,5) --gas-limit 10000000000000000 --fork-block-number 22730425 -vvv

```
or use vm.warp (block.timestamp + 5000)

flexible-vaults/test/integration/BaseIntegrationTest.sol

## Ideas
- focus on logic errors and data validations
- 

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
