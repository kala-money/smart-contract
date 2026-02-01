// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BufferFund is Ownable {
    event ETHReceived(address indexed from, uint256 amount);
    event BufferUpdated(uint256 oldBalance, uint256 newBalance);

    constructor(address owner_) Ownable(owner_) {}

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}
