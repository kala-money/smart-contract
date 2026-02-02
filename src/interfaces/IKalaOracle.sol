// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IKalaOracle
 * @notice Interface for KALA/USD price oracle
 */
interface IKalaOracle {
    /// @notice Returns KALA/USD price with 18 decimals
    function price() external view returns (uint256);
}
