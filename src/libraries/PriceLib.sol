// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library PriceLib {
    uint256 internal constant PRECISION = 1e18;

    uint256 internal constant USDC_FEED_DECIMALS = 8;

    error ZeroDenominator();

    function deriveEthKala(
        uint256 ethUsdPrice,
        uint256 kalaUsdPrice
    ) internal pure returns (uint256) {
        if (kalaUsdPrice == 0) revert ZeroDenominator();
        return Math.mulDiv(ethUsdPrice, PRECISION, kalaUsdPrice);
    }

    function deriveKalaUsdc(
        uint256 kalaUsdPrice,
        uint256 usdcUsdPrice
    ) internal pure returns (uint256) {
        if (usdcUsdPrice == 0) revert ZeroDenominator();
        uint256 usdcScaled = usdcUsdPrice * 1e10;
        return Math.mulDiv(kalaUsdPrice, PRECISION, usdcScaled);
    }

    function ethToUsd(
        uint256 ethAmount,
        uint256 ethUsdPrice
    ) internal pure returns (uint256) {
        return Math.mulDiv(ethAmount, ethUsdPrice, PRECISION);
    }
    function usdToKala(
        uint256 usdValue,
        uint256 kalaUsdPrice
    ) internal pure returns (uint256) {
        if (kalaUsdPrice == 0) revert ZeroDenominator();
        return Math.mulDiv(usdValue, PRECISION, kalaUsdPrice);
    }
}
