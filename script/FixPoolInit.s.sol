// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {FixedPoint96} from "v4-core/libraries/FixedPoint96.sol";
import {KalaHook} from "../src/integration/uniswap/KalaHook.sol";
import {PriceLib} from "../src/libraries/PriceLib.sol";
import {KalaOracle} from "../src/oracle/KalaOracle.sol";
import {IChainlinkFeed} from "../src/interfaces/IChainlinkFeed.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract FixPoolInit is Script {
    using PriceLib for uint256;

    address public constant POOL_MANAGER =
        0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("KALA_DEPLOYER_PK");
        address hookAddress = vm.envAddress("KALA_HOOK_ADDRESS");
        address kalaToken = vm.envAddress("KALA_TOKEN_ADDRESS");
        address wethToken = vm.envOr("WETH_TOKEN_ADDRESS", address(0));

        (uint160 sqrtPriceX96, int24 initialTick) = calculateInitParams(
            hookAddress,
            kalaToken,
            wethToken
        );

        PoolKey memory poolKey = getPoolKey(kalaToken, wethToken, hookAddress);

        console2.log("Calculated Initial Tick:", initialTick);
        console2.log("Calculated SqrtPriceX96:", sqrtPriceX96);

        vm.startBroadcast(deployerPrivateKey);
        IPoolManager(POOL_MANAGER).initialize(
            poolKey,
            TickMath.getSqrtPriceAtTick(initialTick)
        );
        vm.stopBroadcast();

        console2.log(
            "Pool initialized successfully with Oracle-aligned price."
        );
    }

    function calculateInitParams(
        address hookAddress,
        address kalaToken,
        address wethToken
    ) internal view returns (uint160 sqrtPriceX96, int24 initialTick) {
        KalaHook hook = KalaHook(hookAddress);
        KalaOracle oracle = hook.kalaOracle();
        IChainlinkFeed ethFeed = hook.ethUsdFeed();

        (, int256 ethPrice, , , ) = ethFeed.latestRoundData();
        uint256 kalaPrice = oracle.price();
        uint256 ethUsd = uint256(ethPrice) * 1e10;

        uint256 kalaPerEth = PriceLib.deriveEthKala(ethUsd, kalaPrice);
        uint256 targetPriceWad;

        bool isToken0Kala = kalaToken < wethToken;

        if (isToken0Kala) {
            targetPriceWad = (1e36) / kalaPerEth;
            console2.log(
                "Config: Token0 = KALA. Target Price (WETH/KALA):",
                targetPriceWad
            );
        } else {
            targetPriceWad = kalaPerEth;
            console2.log(
                "Config: Token0 = WETH. Target Price (KALA/WETH):",
                targetPriceWad
            );
        }

        sqrtPriceX96 = _getSqrtPriceX96(targetPriceWad);
        int24 tick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);
        int24 tickSpacing = 60;
        initialTick = (tick / tickSpacing) * tickSpacing;
    }

    function getPoolKey(
        address kalaToken,
        address wethToken,
        address hookAddress
    ) internal pure returns (PoolKey memory) {
        bool isToken0Kala = kalaToken < wethToken;
        return
            PoolKey({
                currency0: Currency.wrap(isToken0Kala ? kalaToken : wethToken),
                currency1: Currency.wrap(isToken0Kala ? wethToken : kalaToken),
                fee: 3000,
                tickSpacing: 60,
                hooks: IHooks(hookAddress)
            });
    }

    function _getSqrtPriceX96(
        uint256 priceWad
    ) internal pure returns (uint160) {
        uint256 sqrtPrice = Math.sqrt(priceWad);
        return uint160(Math.mulDiv(sqrtPrice, FixedPoint96.Q96, 1e9));
    }
}
