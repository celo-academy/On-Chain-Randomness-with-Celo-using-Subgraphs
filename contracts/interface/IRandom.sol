// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRandom {
    function random() external view returns (bytes32);
}
