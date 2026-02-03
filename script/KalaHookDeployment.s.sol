// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

import {KalaHook} from "../src/integration/uniswap/KalaHook.sol";
import {HookMiner} from "v4-periphery/utils/HookMiner.sol";

contract KalaHookDeploymentScript is Script {
    address public constant POOL_MANAGER_SEPOLIA =
        0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    address public constant ETH_USD_FEED_SEPOLIA =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address public constant CREATE2_DEPLOYER =
        0x4e59b44847b379578588920cA78FbF26c0B4956C;

    KalaHook public kalaHook;
    IPoolManager public poolManager;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("KALA_DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);
        address kalaOracle = vm.envAddress("ORACLE_ADDRESS");
        address kalaToken = vm.envAddress("KALA_TOKEN_ADDRESS");
        address ethUsdFeed = vm.envOr("ETH_USD_FEED", ETH_USD_FEED_SEPOLIA);
        address poolManagerAddr = vm.envOr(
            "POOL_MANAGER",
            POOL_MANAGER_SEPOLIA
        );

        poolManager = IPoolManager(poolManagerAddr);

        console2.log("==============================================");
        console2.log("KALA Hook Deployment (Sepolia)");
        console2.log("==============================================");
        console2.log("Deployer:       ", deployer);
        console2.log("Balance:        ", deployer.balance);
        console2.log("PoolManager:    ", poolManagerAddr);
        console2.log("KalaOracle:     ", kalaOracle);
        console2.log("KalaToken:      ", kalaToken);
        console2.log("ETH/USD Feed:   ", ethUsdFeed);
        console2.log("");

        console2.log("1. Mining hook address...");

        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);

        bytes memory constructorArgs = abi.encode(
            poolManagerAddr,
            kalaOracle,
            ethUsdFeed,
            kalaToken
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(KalaHook).creationCode,
            constructorArgs
        );

        console2.log("   Hook Address:", hookAddress);
        console2.log("   Salt:        ", vm.toString(salt));
        console2.log("");

        console2.log("2. Deploying KalaHook via CREATE2...");

        vm.startBroadcast(deployerPrivateKey);

        kalaHook = new KalaHook{salt: salt}(
            IPoolManager(poolManagerAddr),
            kalaOracle,
            ethUsdFeed,
            kalaToken
        );

        require(address(kalaHook) == hookAddress, "Hook address mismatch");

        console2.log("   Deployed:    ", address(kalaHook));

        vm.stopBroadcast();

        console2.log("");
        console2.log("==============================================");
        console2.log("Deployment Complete");
        console2.log("==============================================");
        console2.log("KalaHook:       ", address(kalaHook));
        console2.log("PoolManager:    ", poolManagerAddr);
        console2.log("");
        console2.log("To initialize a pool with this hook, call:");
        console2.log("  poolManager.initialize(poolKey, sqrtPriceX96)");
        console2.log("");
        console2.log("PoolKey structure:");
        console2.log("  currency0:    <lower address token>");
        console2.log("  currency1:    <higher address token>");
        console2.log("  fee:          3000 (0.3%)");
        console2.log("  tickSpacing:  60");
        console2.log("  hooks:        ", address(kalaHook));
        console2.log("==============================================");
    }

    function initializePool(
        address currency0,
        address currency1,
        int24 initialTick
    ) external {
        uint256 deployerPrivateKey = vm.envUint("KALA_DEPLOYER_PK");
        address hookAddress = vm.envAddress("KALA_HOOK_ADDRESS");

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(currency0),
            currency1: Currency.wrap(currency1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        uint160 sqrtPriceX96 = TickMath.getSqrtPriceAtTick(initialTick);

        console2.log("Initializing pool...");
        console2.log("  currency0:    ", currency0);
        console2.log("  currency1:    ", currency1);
        console2.log("  tick:         ", initialTick);
        console2.log("  sqrtPriceX96: ", sqrtPriceX96);

        vm.startBroadcast(deployerPrivateKey);

        poolManager.initialize(poolKey, sqrtPriceX96);

        console2.log("Pool initialized.");

        vm.stopBroadcast();
    }
}
