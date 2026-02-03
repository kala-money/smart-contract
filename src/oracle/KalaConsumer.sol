// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReceiverTemplate} from "./ReceiverTemplate.sol";
import {KalaOracle} from "./KalaOracle.sol";

contract KalaConsumer is ReceiverTemplate {
    KalaOracle public oracleContract;

    struct FinalResult {
        uint256 price;
        uint256 T0;
        uint256 G0;
        uint256 S0;
        uint256 B0;
    }

    event ConsumerUpdated(address indexed oracle);

    constructor(
        address _forwarder,
        address _oracle
    ) ReceiverTemplate(_forwarder) {
        oracleContract = KalaOracle(_oracle);
    }

    function setOracle(address _oracle) external onlyOwner {
        oracleContract = KalaOracle(_oracle);
        emit ConsumerUpdated(_oracle);
    }

    function _processReport(bytes calldata report) internal override {
        FinalResult memory finalResult = abi.decode(report, (FinalResult));

        oracleContract.updatePriceData(
            finalResult.price,
            finalResult.T0,
            finalResult.G0,
            finalResult.S0,
            finalResult.B0
        );
    }

    function isResultAnomalous(
        FinalResult memory _prospectiveResult
    ) public view returns (bool) {
        uint256 currentPrice = oracleContract.price();

        if (currentPrice == 0) {
            return false;
        }

        if (_prospectiveResult.price > currentPrice * 2) {
            return true;
        }

        if (_prospectiveResult.price < currentPrice / 2) {
            return true;
        }

        return false;
    }
}
