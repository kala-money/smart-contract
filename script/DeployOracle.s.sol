// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {KalaOracle} from "../src/oracle/KalaOracle.sol";
import {KalaConsumer} from "../src/oracle/KalaConsumer.sol";

contract DeployOracle is Script {
    KalaOracle public oracle;
    KalaConsumer public consumer;

    function setUp() public {}

    function run() external {
        vm.startBroadcast(vm.envUint("KALA_DEPLOYER_PK"));

        oracle = new KalaOracle(100, 1000e8, 10e8, 30, 1e18);
        console2.log("Oracle deployed to:", address(oracle));

        consumer = new KalaConsumer(
            address(oracle),
            address(0xF8344CFd5c43616a4366C34E3EEE75af79a74482)
        );
        console2.log("Consumer deployed to:", address(consumer));

        vm.stopBroadcast();
    }
}
