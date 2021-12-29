// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;
interface IBasePool {
    function getPoolId() external view returns (bytes32);
}