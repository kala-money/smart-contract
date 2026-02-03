// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolModifyLiquidityTest {
    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
        bytes32 salt;
    }

    function modifyLiquidity(
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external payable returns (int256 delta0, int256 delta1);
}

contract KalaPoolInitScript is Script {
    address public constant POOL_MANAGER_SEPOLIA =
        0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    address public constant POOL_MODIFY_LIQUIDITY_TEST =
        0x0C478023803a644c94c4CE1C1e7b9A087e411B0A;
    address public constant KALA_HOOK =
        0xd748e26b7da263861a9559cE59F9c78646Ac0080;
    address public constant KALA_TOKEN =
        0xAF53484b277e9b7e9Fb224D2e534ee9beB68B7BA;

    IPoolManager public poolManager;
    IPoolModifyLiquidityTest public liquidityRouter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("KALA_DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);

        poolManager = IPoolManager(POOL_MANAGER_SEPOLIA);
        liquidityRouter = IPoolModifyLiquidityTest(POOL_MODIFY_LIQUIDITY_TEST);

        // ETH = address(0), KALA = 0xAF53...
        // currency0 must be lower address: ETH (0x0) < KALA
        address currency0 = address(0); // ETH
        address currency1 = KALA_TOKEN; // KALA

        // KALA price = $1, ETH price = ~$2000
        // 1 ETH = 2000 KALA
        // price = KALA/ETH = 1/2000 = 0.0005
        // tick = log_1.0001(0.0005) ≈ -76020
        int24 initialTick = -76020;
        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(initialTick);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(currency0),
            currency1: Currency.wrap(currency1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(KALA_HOOK)
        });

        console2.log("==============================================");
        console2.log("KALA Pool Initialization");
        console2.log("==============================================");
        console2.log("Deployer:       ", deployer);
        console2.log("Balance:        ", deployer.balance);
        console2.log("PoolManager:    ", POOL_MANAGER_SEPOLIA);
        console2.log("Hook:           ", KALA_HOOK);
        console2.log("Currency0 (ETH):", currency0);
        console2.log("Currency1 (KALA):", currency1);
        console2.log("Initial Tick:   ", initialTick);
        console2.log("SqrtPriceX96:   ", sqrtPriceX96);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        console2.log("1. Initializing pool...");
        poolManager.initialize(poolKey, sqrtPriceX96);
        console2.log("   Pool initialized!");

        vm.stopBroadcast();

        console2.log("");
        console2.log("==============================================");
        console2.log("Pool Initialization Complete");
        console2.log("==============================================");
        console2.log("Next step: Add liquidity via addLiquidity function");
        console2.log("==============================================");
    }

    function addLiquidity(uint256 ethAmount, uint256 kalaAmount) external {
        uint256 deployerPrivateKey = vm.envUint("KALA_DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);

        liquidityRouter = IPoolModifyLiquidityTest(POOL_MODIFY_LIQUIDITY_TEST);

        address currency0 = address(0);
        address currency1 = KALA_TOKEN;

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(currency0),
            currency1: Currency.wrap(currency1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(KALA_HOOK)
        });

        int24 tickLower = -887220;
        int24 tickUpper = 887220;

        console2.log("==============================================");
        console2.log("Adding Liquidity to KALA/ETH Pool");
        console2.log("==============================================");
        console2.log("Deployer:       ", deployer);
        console2.log("ETH Amount:     ", ethAmount);
        console2.log("KALA Amount:    ", kalaAmount);
        console2.log("Tick Lower:     ", tickLower);
        console2.log("Tick Upper:     ", tickUpper);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        console2.log("1. Approving KALA token...");
        IERC20(KALA_TOKEN).approve(POOL_MODIFY_LIQUIDITY_TEST, kalaAmount);

        int256 liquidityDelta = int256(ethAmount / 100);

        console2.log("2. Adding liquidity...");
        IPoolModifyLiquidityTest.ModifyLiquidityParams
            memory params = IPoolModifyLiquidityTest.ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: liquidityDelta,
                salt: bytes32(0)
            });

        liquidityRouter.modifyLiquidity{value: ethAmount}(poolKey, params, "");

        console2.log("   Liquidity added!");

        vm.stopBroadcast();

        console2.log("");
        console2.log("==============================================");
        console2.log("Liquidity Addition Complete");
        console2.log("==============================================");
    }
}
