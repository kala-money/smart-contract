// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {KalaMoney} from "../src/core/KalaMoney.sol";
import {BufferFund} from "../src/core/BufferFund.sol";
import {SaveBuffer} from "../src/core/SaveBuffer.sol";
import {CREngine} from "../src/core/CREngine.sol";

contract KalaDeploymentScript is Script {
    BufferFund public bufferFund;
    SaveBuffer public saveBuffer;
    CREngine public crEngine;
    KalaMoney public kalaMoney;

    address public constant ETH_USD_FEED_SEPOLIA =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;

    function run() external {
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("KALA_DEPLOYER_PK");
        address deployer = vm.addr(deployerPrivateKey);
        address ethUsdFeed = vm.envOr("ETH_USD_FEED", ETH_USD_FEED_SEPOLIA);

        console2.log("==============================================");
        console2.log("KALA Protocol Deployment");
        console2.log("==============================================");
        console2.log("Deployer:", deployer);
        console2.log("Balance:", deployer.balance);
        console2.log("Oracle:", oracleAddress);
        console2.log("ETH/USD Feed:", ethUsdFeed);
        console2.log("");

        uint64 nonce = vm.getNonce(deployer);

        address expectedBufferFund = vm.computeCreateAddress(deployer, nonce);
        address expectedCREngine = vm.computeCreateAddress(deployer, nonce + 1);
        address expectedKalaMoney = vm.computeCreateAddress(
            deployer,
            nonce + 2
        );
        address expectedSaveBuffer = vm.computeCreateAddress(
            deployer,
            nonce + 3
        );

        console2.log("Pre-computed addresses:");
        console2.log("  BufferFund:     ", expectedBufferFund);
        console2.log("  CREngine:       ", expectedCREngine);
        console2.log("  KalaMoney:      ", expectedKalaMoney);
        console2.log("  SaveBuffer:     ", expectedSaveBuffer);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        console2.log("1. Deploying BufferFund...");
        bufferFund = new BufferFund(deployer);
        require(
            address(bufferFund) == expectedBufferFund,
            "BufferFund address mismatch"
        );
        console2.log("   Address:", address(bufferFund));

        console2.log("2. Deploying CREngine...");
        crEngine = new CREngine(
            address(bufferFund),
            expectedKalaMoney,
            oracleAddress,
            ethUsdFeed
        );
        require(
            address(crEngine) == expectedCREngine,
            "CREngine address mismatch"
        );
        console2.log("   Address:", address(crEngine));
        console2.log("   kalaToken:", expectedKalaMoney);

        console2.log("3. Deploying KalaMoney...");
        kalaMoney = new KalaMoney(
            address(crEngine),
            address(bufferFund),
            oracleAddress,
            ethUsdFeed
        );
        require(
            address(kalaMoney) == expectedKalaMoney,
            "KalaMoney address mismatch"
        );
        console2.log("   Address:", address(kalaMoney));
        console2.log("   Token:", kalaMoney.name(), kalaMoney.symbol());

        console2.log("4. Deploying SaveBuffer...");
        saveBuffer = new SaveBuffer(address(kalaMoney));
        require(
            address(saveBuffer) == expectedSaveBuffer,
            "SaveBuffer address mismatch"
        );
        console2.log("   Address:", address(saveBuffer));
        console2.log("   KALA_PROTOCOL:", address(kalaMoney));

        console2.log("5. Wiring BufferFund -> KalaMoney...");
        bufferFund.setKalaMoney(address(kalaMoney));
        console2.log("   BufferFund.kalaMoney:", bufferFund.kalaMoney());

        vm.stopBroadcast();

        console2.log("");
        console2.log("==============================================");
        console2.log("Deployment Complete");
        console2.log("==============================================");
        console2.log("BufferFund:     ", address(bufferFund));
        console2.log("CREngine:       ", address(crEngine));
        console2.log("KalaMoney:      ", address(kalaMoney));
        console2.log("SaveBuffer:     ", address(saveBuffer));
        console2.log("");
        console2.log("External:");
        console2.log("Oracle:         ", oracleAddress);
        console2.log("ETH/USD Feed:   ", ethUsdFeed);
        console2.log("==============================================");
    }
}
