// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IChainlink {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract USDCUSD {
    address public usd = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;

    function getPrice() public view returns (uint256) {
        (, int256 quotePrice, , , ) = IChainlink(usd).latestRoundData();
        return uint256(quotePrice);
    }
}
