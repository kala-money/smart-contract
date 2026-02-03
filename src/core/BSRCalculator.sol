// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BufferState} from "../libraries/RiskTypes.sol";

library BSRCalculator {
    uint256 internal constant BPS = 10000;

    uint256 internal constant PRECISION = 1e18;

    uint256 internal constant THICK_THRESHOLD = 1000; // 10% in bps

    uint256 internal constant THIN_THRESHOLD = 200; // 2% in bps

    error ZeroKalaLiability();

    function calculateBSR(
        uint256 bufferEthWei,
        uint256 ethUsdPrice,
        uint256 kalaSupply,
        uint256 kalaUsdPrice
    ) internal pure returns (uint256) {
        if (kalaSupply == 0) {
            return type(uint256).max;
        }
        if (kalaUsdPrice == 0) revert ZeroKalaLiability();

        // Numerator: Buffer value in USD * BPS
        // bufferUsd = bufferEth * ethUsd / PRECISION
        // We keep precision by doing: bufferEth * ethUsd * BPS
        uint256 numerator = bufferEthWei * ethUsdPrice;

        // Denominator: KALA liability in USD
        // kalaLiability = kalaSupply * kalaUsd / PRECISION
        // We keep precision by doing: kalaSupply * kalaUsd
        uint256 denominator = kalaSupply * kalaUsdPrice;

        // BSR_bps = (bufferEth * ethUsd * BPS * PRECISION) / (kalaSupply * kalaUsd * PRECISION)
        // Simplifies to: (numerator * BPS) / denominator
        // Using mulDiv for overflow safety
        return Math.mulDiv(numerator, BPS, denominator);
    }

    function classifyBSR(uint256 bsrBps) internal pure returns (BufferState) {
        if (bsrBps > THICK_THRESHOLD) {
            return BufferState.THICK;
        } else if (bsrBps >= THIN_THRESHOLD) {
            return BufferState.NORMAL;
        } else {
            return BufferState.THIN;
        }
    }

    function calculateAndClassify(
        uint256 bufferEthWei,
        uint256 ethUsdPrice,
        uint256 kalaSupply,
        uint256 kalaUsdPrice
    ) internal pure returns (uint256 bsrBps, BufferState state) {
        bsrBps = calculateBSR(
            bufferEthWei,
            ethUsdPrice,
            kalaSupply,
            kalaUsdPrice
        );
        state = classifyBSR(bsrBps);
    }
}
