## Test 
```
forge test --fork-url $(grep ETH_RPC .env | cut -d '=' -f2,3,4,5) --gas-limit 10000000000000000 --fork-block-number 22730425 -vvv
```

flexible-vaults/test/integration/BaseIntegrationTest.sol

## Ideas