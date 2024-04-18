// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

import "./ReaderUtil.sol";
import "./MarketUtil.sol";
import "./Market.sol";
import "./Price.sol";
import "./DataStore.sol";

interface Reader {
    function getMarkets(DataStore dataStore, uint256 start, uint256 end) external view returns (Market.Props[] memory);

    function getMarketInfo(
        DataStore dataStore,
        MarketUtil.MarketPrices memory prices,
        address marketKey
    ) external view returns (ReaderUtil.MarketInfo memory);

    function getPnl(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getOpenInterestWithPnl(
        DataStore dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);
}
