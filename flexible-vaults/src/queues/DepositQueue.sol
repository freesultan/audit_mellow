// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/queues/IDepositQueue.sol";

import "../libraries/FenwickTreeLibrary.sol";
import "../libraries/TransferLibrary.sol";

import "./Queue.sol";

contract DepositQueue is IDepositQueue, Queue {
    using FenwickTreeLibrary for FenwickTreeLibrary.Tree;
    using Checkpoints for Checkpoints.Trace224; //@>i an OZ library for checkpoints. It is used to store checkpoints of requests and prices. It is updated when a new deposit request is made or when prices are reported.it is 32byte(timestamp) + 224byte(value) = 256byte in total.

    bytes32 private immutable _depositQueueStorageSlot;

    constructor(string memory name_, uint256 version_) Queue(name_, version_) {
        _depositQueueStorageSlot = SlotLibrary.getSlot("DepositQueue", name_, version_);
    }

    // View functions

    /// @inheritdoc IDepositQueue
    function claimableOf(address account) public view returns (uint256) {
        DepositQueueStorage storage $ = _depositQueueStorage();
        //@>i request = (timestamp, assets) of the deposit request of the account
        // @>i if the request is not found, return 0
        // @>i if the request is found, get the price of the request timestamp from the prices tree
        // @>i if the price is not found, return 0
        // @>i if the price is found, calculate the claimable amount = assets * price / 1 ether
          
        Checkpoints.Checkpoint224 memory request = $.requestOf[account];
        if (request._key == 0) {
            return 0;
        }
        //@>i lowerLookup returns the price for the given timestamp                    
        uint256 priceD18 = $.prices.lowerLookup(request._key);

        if (priceD18 == 0) {
            return 0;
        }
        //@>i if price for a request is available, it means that the request is claimable?
        return Math.mulDiv(request._value, priceD18, 1 ether);
    }

    /// @inheritdoc IDepositQueue
    function requestOf(address account) public view returns (uint256 timestamp, uint256 assets) {
        Checkpoints.Checkpoint224 memory request = _depositQueueStorage().requestOf[account];
        return (request._key, request._value);
    }

    /// @inheritdoc IQueue
    function canBeRemoved() external view returns (bool) {
        //@>i a queue can be removed if all requests have been processed and there are no pending requests
        //@>i handledIndices is the index of the last processed timestamp in the Fenwick tree
        //@>i timestamps.length() is the number of timestamps in the Fenwick tree
        //@>i if handledIndices is equal to timestamps.length(), it means that all requests have been processed
        //@>i if handledIndices is less than timestamps.length(), it means that there are still pending requests
        //@>i if handledIndices is greater than timestamps.length(), it means that the Fenwick tree is corrupted
        //@>i so, if handledIndices is equal to timestamps.length(), the queue can be removed
        //@>i this is used to check if the queue can be removed
        return _depositQueueStorage().handledIndices == _timestamps().length();
    }

    // Mutable functions

    /// @inheritdoc IFactoryEntity
    function initialize(bytes calldata data) external initializer {
        (address asset_, address shareModule_,) = abi.decode(data, (address, address, bytes));
        __Queue_init(asset_, shareModule_);
        //@>i initializes enwick tree with 16 buckets hardcoded
        _depositQueueStorage().requests.initialize(16);
        emit Initialized(data);
    }

    /// @inheritdoc IDepositQueue
    //@>test many minimal deposits in one bucket, what's the capacity of one bucket? or tree? 
    //@>test many deposits in one bucket, then cancel one of them
    //@>test many deposits in one bucket, then claim one of them
    //@>test many deposits in one bucket, then claim all of them
    //@>test Race Conditions: simultaneous deposit/cancel calls leading to inconsistent pendingAssets.
    //@>test Deposit amounts at zero, one unit, just below/above limits.
    //@>test  Verify ShareModule → FeeManager → RiskManager → Queue interactions for atomicity.
    function deposit(uint224 assets, address referral, bytes32[] calldata merkleProof) external payable nonReentrant {
        if (assets == 0) {
            revert ZeroValue();
        }
        address caller = _msgSender();
        DepositQueueStorage storage $ = _depositQueueStorage();
        address vault_ = vault();
        //@>i check shareModule storage to see if the queue is paused
        if (IShareModule(vault_).isPausedQueue(address(this))) {
            revert QueuePaused();
        }
        //@>i shareModule is used to manage shares and deposits. here it check if the caller is whitelisted to deposit
        if (!IShareModule(vault_).shareManager().isDepositorWhitelisted(caller, merkleProof)) {
            revert DepositNotAllowed();
        }
        //@>i check if the caller has a pending request = a request that has not been claimed yet
        //@>i each deposit claims for caller, if successful, will reset the request to zero and go on this deposit
        if ($.requestOf[caller]._value != 0 && !_claim(caller)) {
            //@>q attacker: how revert? dos?
            revert PendingRequestExists();
        }

        address asset_ = asset();


        //@>test does not follow CEI. first transfers assets then update states. test for reentrancy, state inconsistency, and asset loss
        TransferLibrary.receiveAssets(asset_, caller, assets);

        //@>i get the current timestamp
        //@>i this is used to track the time of the deposit request
        //@>i timestamp is used to store the request in the Fenwick tree
        //@>i timestamp is used to check if the request is claimable
        //@>i timestamp is used to check if the request is still valid
        //@>i timestamp is used to check if the request is still pending
        uint32 timestamp = uint32(block.timestamp);
        //@>i get timestamps from queueStorage
        Checkpoints.Trace224 storage timestamps = _timestamps();
        //@>i returns: number of checkpoints
        uint256 index = timestamps.length();
        //@>i find the index of the last timestamp that is less than or equal to the current timestamp
        (, uint32 latestTimestamp,) = timestamps.latestCheckpoint();

        if (latestTimestamp < timestamp) {
            //@>i trace224 returns: (uint224 previousValue, uint224 newValue).If the key already exists and equals the latest key, updates the value; otherwise creates a new checkpoin
            timestamps.push(timestamp, uint224(index));
            if ($.requests.length() == index) {//@>i tree is full? 
                //@>i dynamic extending: extend the tree to double its size
                $.requests.extend();//@>i call fenwickTree extend
            }
        } else {
            --index;
        }
        //@>i update pending assets, pending shares, and pending balance in the riskmanager storage
        IVaultModule(vault_).riskManager().modifyPendingAssets(asset_, int256(uint256(assets)));
        //@>i update menwick tree with the new deposit request so that we can track the deposits and their timestamps
        $.requests.modify(index, int256(uint256(assets)));//@>i this will propagate updates through fenwik tree stated with index. add assets to every needed position in array. assets = sum of deposit requests in one bucket(interval)
        //@>i store the request in the requestOf mapping
        $.requestOf[caller] = Checkpoints.Checkpoint224(timestamp, assets);
        emit DepositRequested(caller, referral, assets, timestamp);
    }
 
    /// @inheritdoc IDepositQueue
    function cancelDepositRequest() external nonReentrant {

        address caller = _msgSender();
     
        DepositQueueStorage storage $ = _depositQueueStorage();
        Checkpoints.Checkpoint224 memory request = $.requestOf[caller];
        uint256 assets = request._value;

        if (assets == 0) {
            revert NoPendingRequest();
        }

        address asset_ = asset();
        //@audit: (high) wrongly use prices to get index 
        /*@mitigate: 
             (bool exists, uint32 priceTimestamp, uint256 price) = $.prices.latestCheckpoint(); 
              if (exists && priceTimestamp >= request._key) {
                revert ClaimableRequestExists();
              }
              //then use the right way to get the index like deposit() or _handleReport()
        */
        (bool exists, uint32 timestamp, uint256 index) = $.prices.latestCheckpoint();

        if (exists && timestamp >= request._key) {
            revert ClaimableRequestExists();
        }
        
        //@>i state cleanup
        delete $.requestOf[caller];

        IVaultModule(vault()).riskManager().modifyPendingAssets(asset_, -int256(uint256(assets)));
        //@>i remove the request from the tree
        $.requests.modify(index, -int256(assets));

        TransferLibrary.sendAssets(asset_, caller, assets);
         
        emit DepositRequestCanceled(caller, assets, request._key);
    }
    //@>q how can someone double claim? or claim more? 
    //@>q does after creating shares or/and claiming them, the values reset to zero? or they are still in the tree? is so, are they exploitable?
    /// @inheritdoc IDepositQueue
    function claim(address account) external returns (bool) {
        return _claim(account);
    }

    // Internal functions

    function _claim(address account) internal returns (bool) {
        DepositQueueStorage storage $ = _depositQueueStorage();
        Checkpoints.Checkpoint224 memory request = $.requestOf[account];
        //@>i the existance of the request has checked in the deposit function where _claim is called
        //@>i prices is a collection of checkpoints, each checkpoint is a timestamp and price
        //@>i lowerLookup returns the price for the given timestamp
        uint256 priceD18 = $.prices.lowerLookup(request._key);
        //@>q why do we check if priceD18 is 0? is it possible?
        if (priceD18 == 0) {
            return false;
        }
        //@>i shares = assets * price / 1 ether
        uint256 shares = Math.mulDiv(request._value, priceD18, 1 ether);

        delete $.requestOf[account];
        //@>q is it possible that shares are 0?  
        if (shares != 0) {
            //@>test totalShares = Σ(userBalances) + allocatedShares + contractHeldShares
            IShareModule(vault()).shareManager().mintAllocatedShares(account, shares);
        }
        emit DepositRequestClaimed(account, shares, request._key);
        return true;
    }

    //@>i Handles the report of a new price from the oracle.Batch processing starts here
    function _handleReport(uint224 priceD18, uint32 timestamp) internal override {

        //@>q if felwick tree is corrupted, does this handleReport function still works?
        IShareModule vault_ = IShareModule(vault());

        DepositQueueStorage storage $ = _depositQueueStorage();
        //@>i timestamps is pushed to at deployment and each deposit and redeem request
        Checkpoints.Trace224 storage timestamps = _timestamps();

        uint256 latestEligibleIndex;
        {
            (, uint32 latestTimestamp, uint224 latestIndex) = timestamps.latestCheckpoint();
            if (latestTimestamp <= timestamp) {
                latestEligibleIndex = latestIndex;
            } else {//@>i upperLookupRecent returns the index of the last timestamp that is less than or equal to the given timestamp
                latestEligibleIndex = uint256(timestamps.upperLookupRecent(timestamp));
                if (latestEligibleIndex == 0) {
                    return;
                }
                //@>q why minus 1? 
                latestEligibleIndex--; //@>i decrement to get the last valid index
            }
            //@>q how this is possible? 
            if (latestEligibleIndex < $.handledIndices) {
                return;
            }
        }
        //@>i Computes the total pending deposits in the interval from fenwick tree = all new deposits not yet processed
        uint256 assets = uint256($.requests.get($.handledIndices, latestEligibleIndex));
        //@>q should we check assests?
        $.handledIndices = latestEligibleIndex + 1;

        IFeeManager feeManager = vault_.feeManager();
        uint224 feePriceD18 = uint224(feeManager.calculateDepositFee(priceD18));
        uint224 reducedPriceD18 = priceD18 - feePriceD18;

        $.prices.push(timestamp, reducedPriceD18);

        if (assets == 0) {
            return;
        }

        {
            IShareManager shareManager_ = vault_.shareManager();
            uint256 shares = Math.mulDiv(assets, reducedPriceD18, 1 ether);
            if (shares > 0) {
                //@>q is there a race condition between minting,allocation, and claiming?
                //@>i add shares to the total shares in the share manager storage
                shareManager_.allocateShares(shares);
            }
            uint256 fees = Math.mulDiv(assets, priceD18, 1 ether) - shares;
            if (fees > 0) {
                shareManager_.mint(feeManager.feeRecipient(), fees);
            }
        }

        address asset_ = asset();
        TransferLibrary.sendAssets(asset_, address(vault_), assets);

        IRiskManager riskManager = IVaultModule(address(vault_)).riskManager();
        riskManager.modifyPendingAssets(asset_, -int256(uint256(assets)));
        //@>i update vault amount of shares
        riskManager.modifyVaultBalance(asset_, int256(uint256(assets)));

        vault_.callHook(assets);
    }

    function _depositQueueStorage() internal view returns (DepositQueueStorage storage dqs) {
        bytes32 slot = _depositQueueStorageSlot;
        assembly {
            dqs.slot := slot
        }
    }
}
