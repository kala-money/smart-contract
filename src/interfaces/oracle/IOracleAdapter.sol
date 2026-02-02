// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracleAdapter {
    function getPrice(
        address quoteFeed,
        address baseFeed
    ) external view returns (uint256);
}
