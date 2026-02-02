// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {KalaUnit} from "../token/KalaUnit.sol";
import {BufferFund} from "./BufferFund.sol";
import {PriceLib} from "../oracle/PriceLib.sol";
import {IChainlinkFeed} from "../interfaces/IChainlinkFeed.sol";
import {IKalaOracle} from "../interfaces/IKalaOracle.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract KalaMoney is KalaUnit, ReentrancyGuard {
    using PriceLib for uint256;

    uint256 public constant PRECISION = 1e18;

    uint256 public constant BPS = 10000;

    error ZeroValue();
    error InvalidBufferFund();
    error InvalidOracle();
    error ETHTransferFailed();
    error ExceedsMaxMintable();
    error NegativePrice();
    error InsufficientShares();
    error NoShares();
    error WithdrawDelayNotMet();
    error InsufficientCollateral();

    struct Position {
        uint256 collateral;
        uint256 debt;
        uint256 lastRepayTime;
    }

    event Deposit(
        address indexed user,
        uint256 ethAmount,
        uint256 kalaAmount,
        uint256 ethUsdPrice,
        uint256 kalaUsdPrice,
        uint256 collateralRatioBps
    );

    event Repay(
        address indexed user,
        uint256 kalaAmount,
        uint256 remainingDebt
    );

    event Withdraw(address indexed user, uint256 ethAmount);

    uint256 public constant WITHDRAWAL_DELAY = 3 days;

    IChainlinkFeed public immutable ethUsdFeed;
    IKalaOracle public immutable kalaOracle;
    BufferFund public immutable bufferFund;

    mapping(address => Position) public positions;

    constructor(
        address ethUsdFeed_,
        address kalaOracle_,
        address bufferFund_
    ) KalaUnit() ReentrancyGuard() {
        if (ethUsdFeed_ == address(0)) revert InvalidOracle();
        if (kalaOracle_ == address(0)) revert InvalidOracle();
        if (bufferFund_ == address(0)) revert InvalidBufferFund();

        ethUsdFeed = IChainlinkFeed(ethUsdFeed_);
        kalaOracle = IKalaOracle(kalaOracle_);
        bufferFund = BufferFund(payable(bufferFund_));
    }

    function deposit()
        external
        payable
        nonReentrant
        returns (uint256 kalaAmount)
    {
        if (msg.value == 0) revert ZeroValue();

        (uint256 ethUsdPrice, uint256 kalaUsdPrice) = _getPrices();

        uint256 ethValueUsd = PriceLib.ethToUsd(msg.value, ethUsdPrice);

        kalaAmount = Math.mulDiv(ethValueUsd * BPS, PRECISION, kalaUsdPrice);

        mintShares(msg.sender, kalaAmount);

        Position storage position = positions[msg.sender];
        position.collateral += msg.value;
        position.debt += kalaAmount;
        position.lastRepayTime = block.timestamp;

        (bool success, ) = address(bufferFund).call{value: msg.value}("");
        if (!success) revert ETHTransferFailed();

        uint256 collateralRatioBps = kalaAmount > 0
            ? Math.mulDiv(ethValueUsd, BPS, kalaAmount)
            : 0;

        emit Deposit(
            msg.sender,
            msg.value,
            kalaAmount,
            ethUsdPrice,
            kalaUsdPrice,
            collateralRatioBps
        );
    }

    function previewDeposit(
        uint256 ethAmount
    )
        external
        view
        returns (uint256 kalaAmount, uint256 ethUsdPrice, uint256 kalaUsdPrice)
    {
        (ethUsdPrice, kalaUsdPrice) = _getPrices();

        uint256 ethValueUsd = PriceLib.ethToUsd(ethAmount, ethUsdPrice);

        kalaAmount = Math.mulDiv(ethValueUsd * BPS, PRECISION, kalaUsdPrice);
    }

    function getSystemMetrics()
        external
        view
        returns (uint256 totalKala, uint256 bufferEth)
    {
        totalKala = getTotalShares();
        bufferEth = bufferFund.getBalance();
    }

    function _getPrices()
        internal
        view
        returns (uint256 ethUsdPrice, uint256 kalaUsdPrice)
    {
        (, int256 answer, , , ) = ethUsdFeed.latestRoundData();

        if (answer <= 0) revert NegativePrice();

        uint8 decimals = ethUsdFeed.decimals();
        ethUsdPrice = uint256(answer) * (10 ** (18 - decimals));

        kalaUsdPrice = kalaOracle.price();
    }

    function repay(uint256 kalaAmount) external nonReentrant {
        if (kalaAmount == 0) revert ZeroValue();

        Position storage position = positions[msg.sender];

        uint256 userShares = sharesOf(msg.sender);
        if (userShares < kalaAmount) revert InsufficientShares();

        if (kalaAmount > position.debt) revert InsufficientShares();

        position.debt -= kalaAmount;

        if (position.debt == 0) {
            position.lastRepayTime = block.timestamp;
        }

        _burn(msg.sender, kalaAmount);

        emit Repay(msg.sender, kalaAmount, position.debt);
    }

    function withdraw() external nonReentrant {
        Position storage position = positions[msg.sender];

        if (position.collateral == 0) revert NoShares();

        if (position.debt > 0) revert InsufficientShares();

        if (block.timestamp < position.lastRepayTime + WITHDRAWAL_DELAY) {
            revert WithdrawDelayNotMet();
        }

        uint256 collateralToWithdraw = position.collateral;

        position.collateral = 0;
        position.debt = 0;
        position.lastRepayTime = 0;

        bufferFund.withdraw(msg.sender, collateralToWithdraw);

        emit Withdraw(msg.sender, collateralToWithdraw);
    }
}
