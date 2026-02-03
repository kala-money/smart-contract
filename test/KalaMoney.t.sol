// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BufferFund} from "../src/core/BufferFund.sol";
import {KalaOracle} from "../src/oracle/KalaOracle.sol";
import {VolatilityLevel, LiquidityLevel} from "../src/libraries/RiskTypes.sol";

contract KalaMoneyTest is Test {
    BufferFund public bufferFund;
    KalaOracle public kalaOracle;
    MockChainlinkFeed public ethUsdFeed;

    address public owner;
    address public user1;
    address public user2;

    uint256 constant ETH_USD_PRICE = 2000e8;
    uint256 constant KALA_USD_PRICE = 1.24e18;

    uint256 constant T0 = 100;
    uint256 constant G0 = 200;
    uint256 constant S0 = 300;
    uint256 constant B0 = 400;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        ethUsdFeed = new MockChainlinkFeed(int256(ETH_USD_PRICE), 8);

        bufferFund = new BufferFund(owner);
        kalaOracle = new KalaOracle(T0, G0, S0, B0, KALA_USD_PRICE);
    }

    function test_MockChainlinkFeed() public view {
        (, int256 answer, , uint256 updatedAt, ) = ethUsdFeed.latestRoundData();
        assertEq(answer, int256(ETH_USD_PRICE));
        assertEq(ethUsdFeed.decimals(), 8);
        assertTrue(updatedAt > 0);
    }

    function test_OraclePrice() public view {
        assertEq(kalaOracle.price(), KALA_USD_PRICE);
    }

    function test_OracleRiskLevelDefaults() public view {
        (VolatilityLevel v, LiquidityLevel l) = kalaOracle.getRiskLevels();
        assertTrue(v == VolatilityLevel.NORMAL);
        assertTrue(l == LiquidityLevel.NORMAL);
    }

    function test_OracleRiskLevelUpdate() public {
        kalaOracle.setOracle(address(this));

        kalaOracle.updateRiskLevels(VolatilityLevel.HIGH, LiquidityLevel.THIN);

        (VolatilityLevel v, LiquidityLevel l) = kalaOracle.getRiskLevels();
        assertTrue(v == VolatilityLevel.HIGH);
        assertTrue(l == LiquidityLevel.THIN);
    }

    function test_OraclePriceUpdate() public {
        kalaOracle.setOracle(address(this));

        uint256 newPrice = 1.5e18;
        kalaOracle.updatePriceData(newPrice, T0, G0, S0, B0);

        assertEq(kalaOracle.price(), newPrice);
        assertEq(kalaOracle.latestRoundId(), 2);
    }

    function test_BufferFundReceivesETH() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        (bool success, ) = address(bufferFund).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(bufferFund.getBalance(), 1 ether);
    }

    function test_BufferFundWithdrawTo() public {
        vm.deal(address(bufferFund), 10 ether);

        // Set this test contract as kalaMoney
        bufferFund.setKalaMoney(address(this));

        uint256 balanceBefore = user1.balance;
        bufferFund.withdrawTo(user1, 5 ether);
        assertEq(user1.balance - balanceBefore, 5 ether);
    }

    function test_BufferFundWithdrawToOnlyKalaMoney() public {
        vm.deal(address(bufferFund), 10 ether);

        // Set a different address as kalaMoney
        bufferFund.setKalaMoney(address(0x1234));

        vm.prank(user1);
        vm.expectRevert(BufferFund.Unauthorized.selector);
        bufferFund.withdrawTo(user1, 5 ether);
    }
}

contract MockChainlinkFeed {
    int256 public immutable mockAnswer;
    uint8 public immutable mockDecimals;

    constructor(int256 _answer, uint8 _decimals) {
        mockAnswer = _answer;
        mockDecimals = _decimals;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, mockAnswer, block.timestamp, block.timestamp, 1);
    }

    function decimals() external view returns (uint8) {
        return mockDecimals;
    }
}
