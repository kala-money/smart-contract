// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {KalaUnit} from "../token/KalaUnit.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract KalaMoney is KalaUnit, ReentrancyGuard {
    uint256 public constant PRECISION = 1e18;

    uint256 public constant BPS = 10000;

    error ZeroValue();
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
        uint256 collateralRatioBps
    );

    event Repay(
        address indexed user,
        uint256 kalaAmount,
        uint256 remainingDebt
    );

    event Withdraw(address indexed user, uint256 ethAmount);

    mapping(address => Position) public positions;

    uint256 public constant WITHDRAWAL_DELAY = 3 days;

    constructor(
        address bufferFund_,
        address kalaOracle_
    ) KalaUnit() ReentrancyGuard() {}

    function deposit()
        external
        payable
        nonReentrant
        returns (uint256 kalaAmount)
    {
        if (msg.value == 0) revert ZeroValue();

        emit Deposit(msg.sender, msg.value, kalaAmount);
    }

    function repay(uint256 kalaAmount) external nonReentrant {
        if (kalaAmount == 0) revert ZeroValue();

        Position storage position = positions[msg.sender];

        if (userShares < kalaAmount) revert InsufficientShares();

        if (kalaAmount > position.debt) revert InsufficientShares();

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

        emit Withdraw(msg.sender, collateralToWithdraw);
    }
}
