// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BufferFund is Ownable {
    event ETHReceived(address indexed from, uint256 amount);
    event BufferUpdated(uint256 oldBalance, uint256 newBalance);
    event WithdrawTo(address indexed recipient, uint256 amount);

    error ETHTransferFailed();
    error Unauthorized();
    error InvalidAddress();

    address public kalaMoney;

    modifier onlyKalaMoney() {
        if (msg.sender != kalaMoney) revert Unauthorized();
        _;
    }

    constructor(address owner_) Ownable(owner_) {}

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    function setKalaMoney(address kalaMoney_) external onlyOwner {
        if (kalaMoney_ == address(0)) revert InvalidAddress();
        kalaMoney = kalaMoney_;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getStakingBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawTo(
        address recipient,
        uint256 amount
    ) external onlyKalaMoney {
        (bool success, ) = payable(recipient).call{value: amount}("");
        if (!success) revert ETHTransferFailed();
        emit WithdrawTo(recipient, amount);
    }

    /// @dev Deprecated: Use withdrawTo instead. Kept for backward compatibility.
    function requestETH(uint256 amount) external onlyKalaMoney {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert ETHTransferFailed();
    }
}
