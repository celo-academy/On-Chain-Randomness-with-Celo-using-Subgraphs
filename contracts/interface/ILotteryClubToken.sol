// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ILotteryClubToken {
    function initialize(
        string calldata name_,
        uint256 reward_,
        uint256 deposit_,
        uint256 membersLimit_,
        uint256 managerFee,
        address rewardAddress_,
        address manager_
    ) external;
}
