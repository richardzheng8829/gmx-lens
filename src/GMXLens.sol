// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./interfaces/Keys.sol";
import "./interfaces/Market.sol";
import "./interfaces/Price.sol";
import "./interfaces/Reader.sol";
import "./interfaces/DataStore.sol";

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface AaveOracle {
	function getAssetPrice(address asset) external view returns (uint256);
}

struct MarketDataState {
    address marketToken; 
    address indexToken;
    address longToken;
    address shortToken;
    int256 poolValue; // 30 decimals
    uint256 longTokenAmount; // token decimals
    uint256 longTokenUsd; // 30 decimals
    uint256 shortTokenAmount; // token decimals
    uint256 shortTokenUsd; // 30 decimals
    int256 openInterestLong; // 30 decimals
    int256 openInterestShort; // 30 decimals
    int256 pnlLong; // 30 decimals
    int256 pnlShort; // 30 decimals
    int256 netPnl; // 30 decimals
    uint256 borrowingFactorPerSecondForLongs; // 30 decimals
    uint256 borrowingFactorPerSecondForShorts; // 30 decimals
    bool longsPayShorts;
    uint256 fundingFactorPerSecond; // 30 decimals
    int256 fundingFactorPerSecondLongs; // 30 decimals
    int256 fundingFactorPerSecondShorts; // 30 decimals
    uint256 reservedUsdLong; // 30 decimals
    uint256 reservedUsdShort; // 30 decimals
    uint256 maxOpenInterestUsdLong; // 30 decimals
    uint256 maxOpenInterestUsdShort; // 30 decimals
}

contract GMXLens is UUPSUpgradeable, OwnableUpgradeable {
    DataStore public constant dataStore = DataStore(0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8);
    Reader public constant reader = Reader(0xf60becbba223EEA9495Da3f606753867eC10d139);
    MarketUtil public constant marketUtil = MarketUtil(0x7ffF7ef2fc8Db5159B0046ad49d018A5aB40dB11);

    AaveOracle internal constant oracle = AaveOracle(0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7);

    using Price for Price.Props;
    using SafeCast for int256;
    using SafeCast for uint256;

    bytes32 public constant MARKET_SALT = keccak256(abi.encode("MARKET_SALT"));
    bytes32 public constant MARKET_KEY = keccak256(abi.encode("MARKET_KEY"));
    bytes32 public constant MARKET_TOKEN = keccak256(abi.encode("MARKET_TOKEN"));
    bytes32 public constant INDEX_TOKEN = keccak256(abi.encode("INDEX_TOKEN"));
    bytes32 public constant LONG_TOKEN = keccak256(abi.encode("LONG_TOKEN"));
    bytes32 public constant SHORT_TOKEN = keccak256(abi.encode("SHORT_TOKEN"));

    constructor() {
        _disableInitializers();
    }    

    function initialize() initializer external {
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation) override internal onlyOwner {}

    function getMarketList() external view returns (address[] memory marketIdList) {
        marketIdList = dataStore.getAddressValuesAt(Keys.MARKET_LIST, 0, dataStore.getAddressCount(Keys.MARKET_LIST));
    }

    function getMarketPrices(address market) public view returns (MarketUtil.MarketPrices memory prices) {
        address indexToken = dataStore.getAddress(
            keccak256(abi.encode(market, INDEX_TOKEN))
        );

        address longToken = dataStore.getAddress(
            keccak256(abi.encode(market, LONG_TOKEN))
        );

        address shortToken = dataStore.getAddress(
            keccak256(abi.encode(market, SHORT_TOKEN))
        );
        
        prices.indexTokenPrice.min = oracle.getAssetPrice(indexToken) * 10 ** (22 - IERC20Metadata(indexToken).decimals());
        prices.indexTokenPrice.max = prices.indexTokenPrice.min;
        prices.longTokenPrice.min = oracle.getAssetPrice(longToken) * 10 ** (22 - IERC20Metadata(longToken).decimals());
        prices.longTokenPrice.max = prices.longTokenPrice.min;
        prices.shortTokenPrice.min = oracle.getAssetPrice(shortToken) * 10 ** (22 - IERC20Metadata(shortToken).decimals());
        prices.shortTokenPrice.max = prices.shortTokenPrice.min;
    }


    function getMarketData(address market) external view returns (MarketDataState memory state) {
        MarketUtil.MarketPrices memory prices;
        ReaderUtil.MarketInfo memory marketInfo;
        MarketUtil.MarketPoolValueInfo memory marketPoolValueInfo;

        prices = getMarketPrices(market);
        marketInfo = reader.getMarketInfo(dataStore, prices, market);

        state.marketToken = marketInfo.market.marketToken;
        state.indexToken = marketInfo.market.indexToken;
        state.longToken = marketInfo.market.longToken;
        state.shortToken = marketInfo.market.shortToken;
        state.borrowingFactorPerSecondForLongs = marketInfo.borrowingFactorPerSecondForLongs;
        state.borrowingFactorPerSecondForShorts = marketInfo.borrowingFactorPerSecondForShorts;

        state.longTokenAmount = getPoolAmount(marketInfo.market, state.longToken);
        state.shortTokenAmount = getPoolAmount(marketInfo.market, state.shortToken);
        state.pnlLong = getPnl(marketInfo.market, prices.indexTokenPrice, true, true);
        state.pnlShort = getPnl(marketInfo.market, prices.indexTokenPrice, false, true);
        state.netPnl = state.pnlLong + state.pnlShort;

        state.longTokenUsd = state.longTokenAmount * prices.longTokenPrice.max;
        state.shortTokenUsd = state.shortTokenAmount * prices.shortTokenPrice.max;
        state.poolValue = (state.longTokenUsd + state.shortTokenUsd).toInt256();
        state.poolValue = state.poolValue - state.netPnl;

        state.openInterestLong = reader.getOpenInterestWithPnl(dataStore,
            marketInfo.market,
            prices.indexTokenPrice,
            true,
            true);
        state.openInterestShort = reader.getOpenInterestWithPnl(dataStore,
            marketInfo.market,
            prices.indexTokenPrice,
            false,
            true);

        state.longsPayShorts = marketInfo.nextFunding.longsPayShorts;
        state.fundingFactorPerSecond = marketInfo.nextFunding.fundingFactorPerSecond;
        if (state.longsPayShorts)
            state.fundingFactorPerSecondLongs = int256(state.fundingFactorPerSecond);
        else
            state.fundingFactorPerSecondShorts = int256(state.fundingFactorPerSecond);

        state.reservedUsdLong = getReservedUsd(marketInfo.market, prices, true);
        state.reservedUsdShort = getReservedUsd(marketInfo.market, prices, false);

        state.maxOpenInterestUsdLong = dataStore.getUint(Keys.maxOpenInterestKey(market, true));
        state.maxOpenInterestUsdShort = dataStore.getUint(Keys.maxOpenInterestKey(market, false));
	}

    // @dev get the pending pnl for a market for either longs or shorts
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param indexTokenPrice the price of the index token
    // @param isLong whether to get the pnl for longs or shorts
    // @param maximize whether to maximize or minimize the net pnl
    // @return the pending pnl for a market for either longs or shorts
    function getPnl(
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) internal view returns (int256) {
        int256 openInterest = getOpenInterest(market, isLong).toInt256();
        uint256 openInterestInTokens = getOpenInterestInTokens(market, isLong);
        if (openInterest == 0 || openInterestInTokens == 0) {
            return 0;
        }

        uint256 price = indexTokenPrice.pickPriceForPnl(isLong, maximize);

        // openInterest is the cost of all positions, openInterestValue is the current worth of all positions
        int256 openInterestValue = (openInterestInTokens * price).toInt256();
        int256 pnl = isLong ? openInterestValue - openInterest : openInterest - openInterestValue;

        return pnl;
    }

    function getPoolAmount(Market.Props memory market, address token) internal view returns (uint256) {
        /* Market.Props memory market = MarketStoreUtils.get(dataStore, marketAddress); */
        // if the longToken and shortToken are the same, return half of the token amount, so that
        // calculations of pool value, etc would be correct
        uint256 divisor = getPoolDivisor(market.longToken, market.shortToken);
        return dataStore.getUint(Keys.poolAmountKey(market.marketToken, token)) / divisor;
    }

    // @dev get either the long or short open interest for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param isLong whether to get the long or short open interest
    // @return the long or short open interest for a market
    function getOpenInterest(
        Market.Props memory market,
        bool isLong
    ) internal view returns (uint256) {
        uint256 divisor = getPoolDivisor(market.longToken, market.shortToken);
        uint256 openInterestUsingLongTokenAsCollateral = getOpenInterest(market.marketToken, market.longToken, isLong, divisor);
        uint256 openInterestUsingShortTokenAsCollateral = getOpenInterest(market.marketToken, market.shortToken, isLong, divisor);

        return openInterestUsingLongTokenAsCollateral + openInterestUsingShortTokenAsCollateral;
    }
    // @dev the long and short open interest for a market based on the collateral token used
    // @param dataStore DataStore
    // @param market the market to check
    // @param collateralToken the collateral token to check
    // @param isLong whether to check the long or short side
    function getOpenInterest(
        address market,
        address collateralToken,
        bool isLong,
        uint256 divisor
    ) internal view returns (uint256) {
        return dataStore.getUint(Keys.openInterestKey(market, collateralToken, isLong)) / divisor;
    }

    // this is used to divide the values of getPoolAmount and getOpenInterest
    // if the longToken and shortToken are the same, then these values have to be divided by two
    // to avoid double counting
    function getPoolDivisor(address longToken, address shortToken) internal pure returns (uint256) {
        return longToken == shortToken ? 2 : 1;
    }

    // @dev the long and short open interest in tokens for a market
    // @param dataStore DataStore
    // @param market the market to check
    // @param longToken the long token of the market
    // @param shortToken the short token of the market
    // @param isLong whether to check the long or short side
    function getOpenInterestInTokens(
        Market.Props memory market,
        bool isLong
    ) internal view returns (uint256) {
        uint256 divisor = getPoolDivisor(market.longToken, market.shortToken);
        uint256 openInterestUsingLongTokenAsCollateral = getOpenInterestInTokens(market.marketToken, market.longToken, isLong, divisor);
        uint256 openInterestUsingShortTokenAsCollateral = getOpenInterestInTokens(market.marketToken, market.shortToken, isLong, divisor);

        return openInterestUsingLongTokenAsCollateral + openInterestUsingShortTokenAsCollateral;
    }

    // @dev the long and short open interest in tokens for a market based on the collateral token used
    // @param dataStore DataStore
    // @param market the market to check
    // @param collateralToken the collateral token to check
    // @param isLong whether to check the long or short side
    function getOpenInterestInTokens(
        address market,
        address collateralToken,
        bool isLong,
        uint256 divisor
    ) internal view returns (uint256) {
        return dataStore.getUint(Keys.openInterestInTokensKey(market, collateralToken, isLong)) / divisor;
    }

    function getReservedUsd(
        Market.Props memory market,
        MarketUtil.MarketPrices memory prices,
        bool isLong
    ) internal view returns (uint256) {
        uint256 reservedUsd;
        if (isLong) {
            // for longs calculate the reserved USD based on the open interest and current indexTokenPrice
            // this works well for e.g. an ETH / USD market with long collateral token as WETH
            // the available amount to be reserved would scale with the price of ETH
            // this also works for e.g. a SOL / USD market with long collateral token as WETH
            // if the price of SOL increases more than the price of ETH, additional amounts would be
            // automatically reserved
            uint256 openInterestInTokens = getOpenInterestInTokens(market, isLong);
            reservedUsd = openInterestInTokens * prices.indexTokenPrice.max;
        } else {
            // for shorts use the open interest as the reserved USD value
            // this works well for e.g. an ETH / USD market with short collateral token as USDC
            // the available amount to be reserved would not change with the price of ETH
            reservedUsd = getOpenInterest(market, isLong);
        }

        return reservedUsd;
    }
}


