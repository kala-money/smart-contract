// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {Deployers} from "v4-core-test/utils/Deployers.sol";
import {KalaHook} from "../src/integration/uniswap/KalaHook.sol";
import {KalaOracle} from "../src/oracle/KalaOracle.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {HookMiner} from "v4-periphery/utils/HookMiner.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";

contract ReproductionTest is Test, Deployers {
    KalaHook kalaHook;
    KalaOracle kalaOracle;
    MockERC20 kalaToken;
    MockERC20 usdcToken;

    address ethUsdFeed = makeAddr("ETH_USD_FEED");
    address constant ETH_USD_FEED_SEPOLIA =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;

    function mockEthPrice(int256 price) internal {
        vm.mockCall(
            ethUsdFeed,
            abi.encodeWithSelector(bytes4(keccak256("latestRoundData()"))),
            abi.encode(uint80(1), price, uint256(0), uint256(0), uint80(1))
        );
        vm.mockCall(
            ethUsdFeed,
            abi.encodeWithSelector(bytes4(keccak256("decimals()"))),
            abi.encode(uint8(8))
        );
    }

    function setUp() public {
        deployFreshManagerAndRouters();

        kalaToken = new MockERC20("Kala Unit", "KALA", 18);
        usdcToken = new MockERC20("USDC", "USDC", 6);

        kalaOracle = new KalaOracle(100, 1000e8, 10e8, 30, 1e18);
        mockEthPrice(2000e8);

        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);

        bytes memory constructorArgs = abi.encode(
            manager,
            address(kalaOracle),
            ethUsdFeed,
            address(kalaToken)
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(KalaHook).creationCode,
            constructorArgs
        );

        kalaHook = new KalaHook{salt: salt}(
            manager,
            address(kalaOracle),
            ethUsdFeed,
            address(kalaToken)
        );

        require(
            address(kalaHook) == hookAddress,
            "HookMiner: address mismatch"
        );
    }

    function test_DynamicFee_WhenPriceDeviates() public {
        (Currency c0, Currency c1) = deployMintAndApprove2Currencies();

        if (address(kalaToken) < address(usdcToken)) {
            c0 = Currency.wrap(address(kalaToken));
            c1 = Currency.wrap(address(usdcToken));
        } else {
            c0 = Currency.wrap(address(usdcToken));
            c1 = Currency.wrap(address(kalaToken));
        }

        kalaToken.mint(address(this), 1_000_000e18);
        usdcToken.mint(address(this), 1_000_000e18);

        kalaToken.approve(address(modifyLiquidityRouter), type(uint256).max);
        usdcToken.approve(address(modifyLiquidityRouter), type(uint256).max);
        kalaToken.approve(address(swapRouter), type(uint256).max);
        usdcToken.approve(address(swapRouter), type(uint256).max);
        uint24 dynamicFeeProtocol = 0x800000;

        key = PoolKey(
            c0,
            c1,
            dynamicFeeProtocol,
            60,
            IHooks(address(kalaHook))
        );
        manager.initialize(key, TickMath.getSqrtPriceAtTick(0));

        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 100_000e18,
                salt: bytes32(0)
            }),
            bytes("")
        );

        console2.log("Initial Swap - Oracle Price $2000");
        swap(key, true, 1e18, bytes(""));

        console2.log("Updating Oracle Price to $2500");
        mockEthPrice(2500e8);

        console2.log("Second Swap - Oracle Price $2500");
        swap(key, true, 1e18, bytes(""));
    }
}
