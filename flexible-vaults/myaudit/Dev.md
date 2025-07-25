How the price of oracle is calculated?

Suppose we have multiple external integrations (Uniswap, Symbiotic, Gearbox, Aave). To calculate the price in a given token (`asset`), we need to:

1. Evaluate in asset terms all active positions across these integrations.
2. Include all idle liquidity held both in the main vault and in the subvaults.

This gives us the total value of the system in terms of the asset, which we will call `totalAssets(asset)`.

Next, we need to account for unfulfilled redemption demand:
That includes all redeem batches in every RedeemQueue that have not yet been processed via `handleBatches(n)`.
Lets call the combined value of these batches (converted into the asset) as `totalRedeemDemand(asset)`.

Additionally, we need to include unbatched redemption shares:
These are shares requested for redemption but not yet included in any batch.
We will refer to this as `unprocessedRedeemShares`.

Finally, we have to account for protocol & performance fees, which will be applied during report handling in the ShareModule.
The final `priceD18` can then be calculated as:
```
priceD18 = 
    (shareManager.totalShares() + unprocessedRedeemShares) * 1e18
    / (
        totalAssets(asset) 
        - totalRedeemDemand(asset) 
        + feeManager.calculateFees(vault, asset, priceD18, shareManager.totalShares())
    );
```
As you can see, the equation is recursive - `priceD18` appears on both sides. So we have a couple of options:

1. Just iterate multiple times, starting with the previously reported price as an initial guess. This converges quickly, and it is easy to prove that a fixed point exists and can be reached in a few iterations.

2. Solve this equation analytically. And while it is technically possible it is probably unnecessary here.

cc <@353986240191791106> <@228451601600348160>