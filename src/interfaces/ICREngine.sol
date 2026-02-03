// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VolatilityLevel, LiquidityLevel} from "../libraries/RiskTypes.sol";

interface ICREngine {
    function getTargetCR(
        VolatilityLevel v,
        LiquidityLevel l
    ) external view returns (uint256 crBps);

    function maxMintable(
        uint256 ethValueUsd,
        uint256 kalaUsdPrice,
        VolatilityLevel v,
        LiquidityLevel l
    ) external view returns (uint256 maxKala);

    function getCurrentBSR() external view returns (uint256 bsrBps);
}
