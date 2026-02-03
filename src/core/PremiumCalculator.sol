// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    VolatilityLevel,
    LiquidityLevel,
    BufferState
} from "../libraries/RiskTypes.sol";

library PremiumCalculator {
    uint256 internal constant VOLATILITY_HIGH_PREMIUM = 3000; // +30%

    uint256 internal constant LIQUIDITY_NORMAL_PREMIUM = 500; // +5%

    uint256 internal constant LIQUIDITY_THIN_PREMIUM = 1000; // +10%

    uint256 internal constant BUFFER_THICK_DISCOUNT = 2000; // -20%

    uint256 internal constant BUFFER_NORMAL_DISCOUNT = 1000; // -10%

    function volatilityPremium(
        VolatilityLevel level
    ) internal pure returns (uint256) {
        if (level == VolatilityLevel.HIGH) {
            return VOLATILITY_HIGH_PREMIUM;
        }
        return 0;
    }

    function liquidityPremium(
        LiquidityLevel level
    ) internal pure returns (uint256) {
        if (level == LiquidityLevel.THIN) {
            return LIQUIDITY_THIN_PREMIUM;
        } else if (level == LiquidityLevel.NORMAL) {
            return LIQUIDITY_NORMAL_PREMIUM;
        }
        return 0;
    }

    function bufferDiscount(BufferState state) internal pure returns (uint256) {
        if (state == BufferState.THICK) {
            return BUFFER_THICK_DISCOUNT;
        } else if (state == BufferState.NORMAL) {
            return BUFFER_NORMAL_DISCOUNT;
        }
        return 0;
    }

    function calculateAdjustment(
        VolatilityLevel v,
        LiquidityLevel l,
        BufferState bsr
    ) internal pure returns (uint256, bool) {
        uint256 totalPremium = volatilityPremium(v) + liquidityPremium(l);
        uint256 discount = bufferDiscount(bsr);

        if (totalPremium >= discount) {
            return (totalPremium - discount, false);
        } else {
            return (discount - totalPremium, true);
        }
    }
}
