// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {
    BeforeSwapDelta,
    BeforeSwapDeltaLibrary
} from "v4-core/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {FullMath} from "v4-core/libraries/FullMath.sol";
import {FixedPoint96} from "v4-core/libraries/FixedPoint96.sol";

import {KalaOracle} from "../../oracle/KalaOracle.sol";
import {PriceLib} from "../../libraries/PriceLib.sol";
import {IChainlinkFeed} from "../../interfaces/IChainlinkFeed.sol";

contract KalaHook is BaseHook {
    using StateLibrary for IPoolManager;
    using CurrencyLibrary for Currency;
    using PriceLib for uint256;

    KalaOracle public immutable kalaOracle;
    IChainlinkFeed public immutable ethUsdFeed;
    address public immutable kalaToken;

    uint256 public constant MAX_DEVIATION_BPS = 500;
    uint256 public constant BPS = 10000;
    uint256 public constant PRECISION = 1e18;

    error InvalidOracle();
    error InvalidFeed();
    error InvalidToken();
    error PriceDeviationTooHigh(
        uint256 spotPrice,
        uint256 targetPrice,
        uint256 deviation
    );
    error NegativePrice();
    error ZeroDenominator();

    event OracleCheck(
        uint256 oraclePriceWad,
        uint256 poolPriceWad,
        uint256 deviationBps
    );

    constructor(
        IPoolManager _poolManager,
        address _kalaOracle,
        address _ethUsdFeed,
        address _kalaToken
    ) BaseHook(_poolManager) {
        if (_kalaOracle == address(0)) revert InvalidOracle();
        if (_ethUsdFeed == address(0)) revert InvalidFeed();
        if (_kalaToken == address(0)) revert InvalidToken();

        kalaOracle = KalaOracle(_kalaOracle);
        ethUsdFeed = IChainlinkFeed(_ethUsdFeed);
        kalaToken = _kalaToken;
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _beforeSwap(
        address, // sender
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata // hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        bool isCurrency0Kala = Currency.unwrap(key.currency0) == kalaToken;
        bool isCurrency1Kala = Currency.unwrap(key.currency1) == kalaToken;

        if (!isCurrency0Kala && !isCurrency1Kala) {
            return (
                this.beforeSwap.selector,
                BeforeSwapDeltaLibrary.ZERO_DELTA,
                0
            );
        }

        (uint160 sqrtPriceX96, , , ) = poolManager.getSlot0(key.toId());

        uint256 targetPriceWad = _getTargetPrice(isCurrency0Kala);

        uint256 currentPriceWad = _getPoolPriceWad(sqrtPriceX96);

        uint256 lowerBound = (targetPriceWad * (BPS - MAX_DEVIATION_BPS)) / BPS;
        uint256 upperBound = (targetPriceWad * (BPS + MAX_DEVIATION_BPS)) / BPS;

        bool isWithinBounds = currentPriceWad >= lowerBound &&
            currentPriceWad <= upperBound;

        if (!isWithinBounds) {
            if (currentPriceWad < lowerBound) {
                if (params.zeroForOne) {
                    revert PriceDeviationTooHigh(
                        currentPriceWad,
                        targetPriceWad,
                        0
                    );
                }
            } else if (currentPriceWad > upperBound) {
                if (!params.zeroForOne) {
                    revert PriceDeviationTooHigh(
                        currentPriceWad,
                        targetPriceWad,
                        0
                    );
                }
            }
        }
        emit OracleCheck(targetPriceWad, currentPriceWad, 0);

        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _getTargetPrice(
        bool isCurrency0Kala
    ) internal view returns (uint256) {
        (uint256 ethUsd, uint256 kalaUsd) = _getOraclePrices();

        if (isCurrency0Kala) {
            uint256 kalaPerEth = PriceLib.deriveEthKala(ethUsd, kalaUsd);
            if (kalaPerEth == 0) revert ZeroDenominator();
            return (PRECISION * PRECISION) / kalaPerEth;
        } else {
            return PriceLib.deriveEthKala(ethUsd, kalaUsd);
        }
    }

    function _getOraclePrices()
        internal
        view
        returns (uint256 ethUsd, uint256 kalaUsd)
    {
        (, int256 answer, , , ) = ethUsdFeed.latestRoundData();
        if (answer <= 0) revert NegativePrice();

        uint8 decimals = ethUsdFeed.decimals();
        ethUsd = uint256(answer) * (10 ** (18 - decimals));

        kalaUsd = kalaOracle.price();
    }

    function _getPoolPriceWad(
        uint160 sqrtPriceX96
    ) internal pure returns (uint256 priceWad) {
        uint256 sqrtPriceX96Uint = uint256(sqrtPriceX96);
        uint256 priceX192 = FullMath.mulDiv(
            sqrtPriceX96Uint,
            sqrtPriceX96Uint,
            1
        );

        priceWad = FullMath.mulDiv(priceX192, PRECISION, 1 << 192);
    }
}
