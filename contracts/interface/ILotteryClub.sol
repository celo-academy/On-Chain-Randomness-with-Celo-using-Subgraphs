// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ILotteryClub {
    function initialize(
        string calldata name_,
        uint256 reward_,
        uint256 deposit_,
        uint256 membersLimit_,
        uint256 managerFee_,
        address manager_,
        address rewardAddress_
    ) external;
}
