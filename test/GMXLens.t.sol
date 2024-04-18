// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/GMXLens.sol";

contract GMXLensTest is Test {
    function setUp() public {
    }

    function testLens() public {        
        address owner = 0x349CF949BF40cd86586440d4b84E189e4f119210;

        vm.createSelectFork("arbitrum");
        vm.startPrank(owner);

        address impl = address(new GMXLens());
        GMXLens lens = GMXLens(
            address(new ERC1967Proxy(impl, abi.encodeWithSignature("initialize()"))));

        vm.label(address(lens), "Lens");
        vm.label(address(lens.dataStore()), "dataStore");
        vm.label(address(lens.reader()), "reader");
        vm.label(address(lens.marketUtil()), "marketUtil");
        vm.stopPrank();

        // address[] memory marketIdList = lens.getMarketList();

        // for (uint256 i = 0; i < marketIdList.length; i++) {
            address marketId = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;
            MarketDataState memory state = lens.getMarketData(marketId);

            console.log("---------");
            console.log("marketId:",  marketId);
            console.log("marketToken:",  IERC20Metadata(state.marketToken).symbol(), state.marketToken);
            console.log("indexToken:",  IERC20Metadata(state.indexToken).symbol(), state.indexToken);
            console.log("longToken:",  IERC20Metadata(state.longToken).symbol(), state.longToken);
            console.log("shortToken:",  IERC20Metadata(state.shortToken).symbol(), state.shortToken);
            emit log_named_decimal_int("poolValue:",  state.poolValue, 30);
            emit log_named_decimal_uint("longTokenAmount:",  state.longTokenAmount, IERC20Metadata(state.longToken).decimals());
            emit log_named_decimal_uint("longTokenUsd:",  state.longTokenUsd, 30);
            emit log_named_decimal_uint("shortTokenAmount:",  state.shortTokenAmount, IERC20Metadata(state.shortToken).decimals());
            emit log_named_decimal_uint("shortTokenUsd:",  state.shortTokenUsd, 30);
            emit log_named_decimal_int("openInterestLong:",  state.openInterestLong, 30);
            emit log_named_decimal_int("openInterestShort:",  state.openInterestShort, 30);
            emit log_named_decimal_int("pnlLong:",  state.pnlLong, 30);
            emit log_named_decimal_int("pnlShort:",  state.pnlShort, 30);
            emit log_named_decimal_int("netPnl:",  state.netPnl, 30);
            emit log_named_decimal_uint("borrowingFactorPerSecondForLongs:",  state.borrowingFactorPerSecondForLongs, 30);
            emit log_named_decimal_uint("borrowingFactorPerSecondForShorts:",  state.borrowingFactorPerSecondForShorts, 30);
            console.log("longsPayShorts:",  state.longsPayShorts);
            emit log_named_decimal_uint("fundingFactorPerSecond:",  state.fundingFactorPerSecond, 30);
            emit log_named_decimal_int("fundingFactorPerSecondLongs:",  state.fundingFactorPerSecondLongs, 30);
            emit log_named_decimal_int("fundingFactorPerSecondShorts:",  state.fundingFactorPerSecondShorts, 30);
            emit log_named_decimal_uint("reservedUsdLong:",  state.reservedUsdLong, 30);
            emit log_named_decimal_uint("reservedUsdShort:",  state.reservedUsdShort, 30);
            emit log_named_decimal_uint("maxOpenInterestUsdLong:",  state.maxOpenInterestUsdLong, 30);
            emit log_named_decimal_uint("maxOpenInterestUsdShort:",  state.maxOpenInterestUsdShort, 30);

        //     break;
        // }
    }
}
