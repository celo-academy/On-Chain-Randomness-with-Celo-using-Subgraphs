// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ILottreyClubStable {
    function initialize(string calldata _name, uint256 _prize, uint256 _deposit, uint256 _membersLimit, address _prizeAddress, address _manager) external;
}
