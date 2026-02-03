// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Deployers} from "v4-core-test/utils/Deployers.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";

import {KalaHook} from "../../../src/integration/uniswap/KalaHook.sol";
import {KalaOracle} from "../../../src/oracle/KalaOracle.sol";
import {IChainlinkFeed} from "../../../src/interfaces/IChainlinkFeed.sol";

contract MockChainlinkFeed is IChainlinkFeed {
    int256 public price;
    uint8 public decimalsVal;

    constructor(int256 _price, uint8 _decimals) {
        price = _price;
        decimalsVal = _decimals;
    }

    function setPrice(int256 _price) public {
        price = _price;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, price, block.timestamp, block.timestamp, 1);
    }

    function decimals() external view override returns (uint8) {
        return decimalsVal;
    }
}

contract MockKalaOracle {
    uint256 public priceVal;

    constructor(uint256 _price) {
        priceVal = _price;
    }

    function setPrice(uint256 _price) public {
        priceVal = _price;
    }

    function price() external view returns (uint256) {
        return priceVal;
    }
}

contract KalaHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;

    KalaHook hook;
    MockKalaOracle kalaOracle;
    MockChainlinkFeed ethUsdFeed;

    address kalaToken;
    address ethToken;

    function setUp() public {
        deployFreshManagerAndRouters();

        ethUsdFeed = new MockChainlinkFeed(2000 * 1e8, 8);
        kalaOracle = new MockKalaOracle(1e18);

        deployMintAndApprove2Currencies();

        kalaToken = Currency.unwrap(currency0);
        ethToken = Currency.unwrap(currency1);

        address hookAddress = address(uint160(Hooks.BEFORE_SWAP_FLAG));

        deployCodeTo(
            "KalaHook.sol",
            abi.encode(
                manager,
                address(kalaOracle),
                address(ethUsdFeed),
                kalaToken
            ),
            hookAddress
        );
        hook = KalaHook(hookAddress);

        uint160 startSqrtPrice = TickMath.getSqrtPriceAtTick(-76020);

        (key, ) = initPool(currency0, currency1, hook, 3000, startSqrtPrice);

        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -76500,
                tickUpper: -75540,
                liquidityDelta: 100 ether,
                salt: 0
            }),
            ZERO_BYTES
        );
    }

    function test_Initialization() public view {
        assertEq(address(hook.kalaOracle()), address(kalaOracle));
    }

    function test_AllowedSwap() public {
        swap(key, true, 0.001 ether, ZERO_BYTES); // 0.001 KALA inputs
    }

    function test_RevertIfDeviationHigh() public {
        kalaOracle.setPrice(10 ether);
        vm.expectRevert();
        swap(key, true, 0.001 ether, ZERO_BYTES);
    }

    function test_AllowStabilizingArbitrage() public {
        kalaOracle.setPrice(10 ether);

        swap(key, false, 0.001 ether, ZERO_BYTES);
    }
}
