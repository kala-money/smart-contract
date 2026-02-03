// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract LiquidityBuffer {
    uint256 public liquidityBuffer;

    constructor() {
        liquidityBuffer = 0;
    }

    function setLiquidityBuffer(uint256 amount) public {
        liquidityBuffer = amount;
    }
}
