// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {VolatilityLevel, LiquidityLevel} from "../libraries/RiskTypes.sol";

contract KalaOracle is Ownable {
    uint256 public price;
    uint256 public lastUpdateTime;
    address public oracle;

    VolatilityLevel public volatilityLevel;
    LiquidityLevel public liquidityLevel;

    struct RoundData {
        uint256 price;
        uint256 t0;
        uint256 g0;
        uint256 s0;
        uint256 b0;
        uint256 timestamp;
    }

    uint256 public latestRoundId;
    mapping(uint256 => RoundData) public rounds;

    event PriceUpdated(
        uint256 indexed roundId,
        uint256 indexed timestamp,
        uint256 price,
        uint256 t0,
        uint256 g0,
        uint256 s0,
        uint256 b0
    );

    event OracleUpdated(address indexed oldOracle, address indexed newOracle);

    event RiskLevelsUpdated(
        VolatilityLevel volatility,
        LiquidityLevel liquidity
    );

    error Unauthorized();
    error InvalidData();

    modifier onlyOracle() {
        if (msg.sender != oracle && msg.sender != owner())
            revert Unauthorized();
        _;
    }

    constructor(
        uint256 _T0,
        uint256 _G0,
        uint256 _S0,
        uint256 _B0,
        uint256 _price
    ) Ownable(msg.sender) {
        if (_T0 == 0 || _G0 == 0 || _S0 == 0 || _B0 == 0) revert InvalidData();

        latestRoundId = 1;
        price = _price;
        lastUpdateTime = block.timestamp;

        volatilityLevel = VolatilityLevel.NORMAL;
        liquidityLevel = LiquidityLevel.NORMAL;

        rounds[latestRoundId] = RoundData({
            price: _price,
            t0: _T0,
            g0: _G0,
            s0: _S0,
            b0: _B0,
            timestamp: block.timestamp
        });

        emit PriceUpdated(
            latestRoundId,
            block.timestamp,
            _price,
            _T0,
            _G0,
            _S0,
            _B0
        );
    }

    function setOracle(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert InvalidData();
        emit OracleUpdated(oracle, _newOracle);
        oracle = _newOracle;
    }

    function updatePriceData(
        uint256 _price,
        uint256 _t0,
        uint256 _g0,
        uint256 _s0,
        uint256 _b0
    ) external onlyOracle {
        if (_price == 0) revert InvalidData();

        latestRoundId++;

        price = _price;
        lastUpdateTime = block.timestamp;

        rounds[latestRoundId] = RoundData({
            price: _price,
            t0: _t0,
            g0: _g0,
            s0: _s0,
            b0: _b0,
            timestamp: block.timestamp
        });

        emit PriceUpdated(
            latestRoundId,
            block.timestamp,
            _price,
            _t0,
            _g0,
            _s0,
            _b0
        );
    }

    function updateRiskLevels(
        VolatilityLevel _volatility,
        LiquidityLevel _liquidity
    ) external onlyOracle {
        volatilityLevel = _volatility;
        liquidityLevel = _liquidity;

        emit RiskLevelsUpdated(_volatility, _liquidity);
    }

    function getRiskLevels()
        external
        view
        returns (VolatilityLevel volatility, LiquidityLevel liquidity)
    {
        return (volatilityLevel, liquidityLevel);
    }

    function getRoundData(
        uint256 _roundId
    ) external view returns (RoundData memory) {
        return rounds[_roundId];
    }
}
