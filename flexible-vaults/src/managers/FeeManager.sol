// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/managers/IFeeManager.sol";

import "../libraries/SlotLibrary.sol";

contract FeeManager is IFeeManager, OwnableUpgradeable {
    bytes32 private immutable _feeManagerStorageSlot;

    constructor(string memory name_, uint256 version_) {
        _feeManagerStorageSlot = SlotLibrary.getSlot("FeeManager", name_, version_);
        _disableInitializers();
    }

    // View functions

    /// @inheritdoc IFeeManager
    function feeRecipient() public view returns (address) {
        return _feeManagerStorage().feeRecipient;
    }

    /// @inheritdoc IFeeManager
    function depositFeeD6() public view returns (uint24) {
        return _feeManagerStorage().depositFeeD6;
    }

    /// @inheritdoc IFeeManager
    function redeemFeeD6() public view returns (uint24) {
        return _feeManagerStorage().redeemFeeD6;
    }

    /// @inheritdoc IFeeManager
    function performanceFeeD6() public view returns (uint24) {
        return _feeManagerStorage().performanceFeeD6;
    }

    /// @inheritdoc IFeeManager
    function protocolFeeD6() public view returns (uint24) {
        return _feeManagerStorage().protocolFeeD6;
    }

    /// @inheritdoc IFeeManager
    function timestamps(address vault) public view returns (uint256) {
        return _feeManagerStorage().timestamps[vault];
    }

    /// @inheritdoc IFeeManager
    function minPriceD18(address vault) public view returns (uint256) {
        return _feeManagerStorage().minPriceD18[vault];
    }

    /// @inheritdoc IFeeManager
    function baseAsset(address vault) public view returns (address) {
        return _feeManagerStorage().baseAsset[vault];
    }

    /// @inheritdoc IFeeManager
    function calculateDepositFee(uint256 shares) public view returns (uint256) {
        return (shares * depositFeeD6()) / 1e6;
    }

    /// @inheritdoc IFeeManager
    function calculateRedeemFee(uint256 shares) public view returns (uint256) {
        return (shares * redeemFeeD6()) / 1e6;
    }
    //@>Test Simulate large TVL, massive fee rates, long stale intervals

    /// @inheritdoc IFeeManager
    function calculateFee(address vault, address asset, uint256 priceD18, uint256 totalShares)
        public
        view
        returns (uint256 shares)
    {
        
        FeeManagerStorage storage $ = _feeManagerStorage();
        //@>i perfomance fee calculation only for baseAsset (Every vault has a base asset)
        if (asset == $.baseAsset[vault]) {
            uint256 minPriceD18_ = $.minPriceD18[vault];
            //@>i if the current price is less than the minimum historical recorded price( Watermark), calculate performance fee
            //@>i Lower price = fewer shares per asset = better vault performance
            if (priceD18 < minPriceD18_ && minPriceD18_ != 0) {
                //@>i 1e18 * 1e6 = 1e24 / 1e24
                shares = Math.mulDiv(minPriceD18_ - priceD18, $.performanceFeeD6 * totalShares, 1e24);
            }
        }

        //@>i protocol fee calculation based on last recorded timestamp
        // If the timestamp is zero, it means the protocol fee has not been recorded yet
        // The protocol fee is calculated as a fraction of the total shares based on the time elapsed
        // The formula used is: (totalShares * protocolFeeD6 * (currentTimestamp - recordedTimestamp)) / (365 * 1e6 days)
        // This effectively accrues the protocol fee over time, assuming a yearly rate
        // The protocol fee is expressed in D6 precision, meaning it is scaled by 1e6
        // The result is added to `shares`, which represents the total fee in shares to be deducted
        uint256 timestamp = $.timestamps[vault];

        if (timestamp != 0 && block.timestamp > timestamp) {
            /*@>missed exponential compounding instead of linear accumulation leading to higher-than-intended fee extraction
            every time this function is called, it also includes shares which have already been accrued
            this can lead to an exponential increase in the fee over time, especially if the function is
            called frequently or if the time interval between calls is short.
             
            It's better to calculate the fee based on assets then mint shared to the fee recipient
            */
            shares += Math.mulDiv(totalShares, $.protocolFeeD6 * (block.timestamp - timestamp), 365e6 days);
        }
    }

    // Mutable functions

    /// @inheritdoc IFeeManager
    function setFeeRecipient(address feeRecipient_) external onlyOwner {
        _setFeeRecipient(feeRecipient_);
    }

    /// @inheritdoc IFeeManager
    function setFees(uint24 depositFeeD6_, uint24 redeemFeeD6_, uint24 performanceFeeD6_, uint24 protocolFeeD6_)
        external
        onlyOwner
    {
        _setFees(depositFeeD6_, redeemFeeD6_, performanceFeeD6_, protocolFeeD6_);
    }

    /// @inheritdoc IFeeManager
    function setBaseAsset(address vault, address baseAsset_) external onlyOwner {
        if (vault == address(0) || baseAsset_ == address(0)) {
            revert ZeroAddress();
        }
        FeeManagerStorage storage $ = _feeManagerStorage();
        if ($.baseAsset[vault] != address(0)) {
            revert BaseAssetAlreadySet(vault, $.baseAsset[vault]);
        }
        $.baseAsset[vault] = baseAsset_;
        emit SetBaseAsset(vault, baseAsset_);
    }

    //@>q why there is no setminPriceD18 function? 

    /// @inheritdoc IFeeManager
    function updateState(address asset, uint256 priceD18) external {
        FeeManagerStorage storage $ = _feeManagerStorage();
        address vault = _msgSender();
        /*@>missed if the asset is not base addet don't update the timestamp. 
        why missed? because I didn't know why this condition is used, what happens if this condition is not here?
        finder: timestamp should be updated even for non-base assets, as it tracks the last update time for the vault.
        */
        if ($.baseAsset[vault] != asset) {
            return;
        }
        uint256 minPriceD18_ = $.minPriceD18[vault];
        //@>i update the minPriceD18 and timestamps for the vault. saving and tracking low watermark,
        //@>q this only update minPriced18 if the current price is lower than the previous minimum, but what if price rises and the drops?
        if (minPriceD18_ == 0 || minPriceD18_ > priceD18) {
            $.minPriceD18[vault] = priceD18;
        }
        $.timestamps[vault] = block.timestamp;
        emit UpdateState(vault, asset, priceD18);
    }

    /// @inheritdoc IFactoryEntity
    function initialize(bytes calldata data) external initializer {
        (
            address owner_,
            address feeRecipient_,
            uint24 depositFeeD6_,
            uint24 redeemFeeD6_,
            uint24 performanceFeeD6_,
            uint24 protocolFeeD6_
        ) = abi.decode(data, (address, address, uint24, uint24, uint24, uint24));
        __Ownable_init(owner_);
        _setFeeRecipient(feeRecipient_);
        _setFees(depositFeeD6_, redeemFeeD6_, performanceFeeD6_, protocolFeeD6_);
        emit Initialized(data);
    }

    // Internal functions

    function _setFeeRecipient(address feeRecipient_) internal {
        if (feeRecipient_ == address(0)) {
            revert ZeroAddress();
        }
        FeeManagerStorage storage $ = _feeManagerStorage();
        $.feeRecipient = feeRecipient_;
        emit SetFeeRecipient(feeRecipient_);
    }

    function _setFees(uint24 depositFeeD6_, uint24 redeemFeeD6_, uint24 performanceFeeD6_, uint24 protocolFeeD6_)
        internal
    {
        /*
        @>missed (medium) we must force fee collection before setting new fees
        */
        if (depositFeeD6_ + redeemFeeD6_ + performanceFeeD6_ + protocolFeeD6_ > 1e6) {
            revert InvalidFees(depositFeeD6_, redeemFeeD6_, performanceFeeD6_, protocolFeeD6_);
        }
        FeeManagerStorage storage $ = _feeManagerStorage();
        $.depositFeeD6 = depositFeeD6_;
        $.redeemFeeD6 = redeemFeeD6_;
        $.performanceFeeD6 = performanceFeeD6_;
        $.protocolFeeD6 = protocolFeeD6_;
        emit SetFees(depositFeeD6_, redeemFeeD6_, performanceFeeD6_, protocolFeeD6_);
    }

    function _feeManagerStorage() internal view returns (FeeManagerStorage storage $) {
        bytes32 slot = _feeManagerStorageSlot;
        assembly {
            $.slot := slot
        }
    }
}
