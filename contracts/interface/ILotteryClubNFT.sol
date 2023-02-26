// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ILotteryClubNFT {
    function initialize(
        string calldata name_,
        uint256 deposit_,
        uint256 membersLimit_,
        address manager_
    ) external;
}
