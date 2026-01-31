// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract KalaMoney is Ownable {
    constructor() Ownable(msg.sender) {}

    function deposit() public {
        uint256 shares = 0;
        if (shares == 0) {}
    }

    function withdraw() public {
        uint256 shares = 0;
        if (shares == 0) {}
    }
}
