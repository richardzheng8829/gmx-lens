## GMX Lens Contract Test Results

forge test --match-test Lens -vvv

```
Running 1 test for test/GMXLens.t.sol:GMXLensTest
[PASS] testLens() (gas: 2892979)
Logs:
  ---------
  marketId: 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336
  marketToken: GM 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336
  indexToken: WETH 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
  longToken: WETH 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
  shortToken: USDC 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
  poolValue:: 89658686.036305249165312419534830080000
  longTokenAmount:: 15061.833399686891128576
  longTokenUsd:: 45115833.011551249165312419534830080000
  shortTokenAmount:: 44542853.024754
  shortTokenUsd:: 44542853.024754000000000000000000000000
  openInterestLong:: 28961205.711021071872920984048628530000
  openInterestShort:: 27514803.703716268628083065759257290504
  pnlLong:: -861380.379509835142662811816044267199
  pnlShort:: 168229.640977645784986056215608160252
  netPnl:: -693150.738532189357676755600436106947
  borrowingFactorPerSecondForLongs:: 0.000000005639696143061923857998
  borrowingFactorPerSecondForShorts:: 0.000000000000000000000000000000
  longsPayShorts: true
  fundingFactorPerSecond:: 0.000000007053040433944739973168
  fundingFactorPerSecondLongs:: 0.000000007053040433944739973168
  fundingFactorPerSecondShorts:: 0.000000000000000000000000000000
  reservedUsdLong:: 28961205.711021071872920984048628530000
  reservedUsdShort:: 27346574.062738622843097009543649130252
  maxOpenInterestUsdLong:: 80000000.000000000000000000000000000000
  maxOpenInterestUsdShort:: 80000000.000000000000000000000000000000
```