// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

import "./MarketUtil.sol";
import "./Market.sol";
interface ReaderUtil {
    struct VirtualInventory {
        uint256 virtualPoolAmountForLongToken;
        uint256 virtualPoolAmountForShortToken;
        int256 virtualInventoryForPositions;
    }

    struct MarketInfo {
        Market.Props market;
        uint256 borrowingFactorPerSecondForLongs;
        uint256 borrowingFactorPerSecondForShorts;
        BaseFundingValues baseFunding;
        MarketUtil.GetNextFundingAmountPerSizeResult nextFunding;
        VirtualInventory virtualInventory;
        bool isDisabled;
    }

    struct BaseFundingValues {
        MarketUtil.PositionType fundingFeeAmountPerSize;
        MarketUtil.PositionType claimableFundingAmountPerSize;
    }
}
