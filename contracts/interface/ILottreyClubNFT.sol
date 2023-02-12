// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ILottreyClubNFT {
    function initialize(string calldata _name, uint256 _ticketPrice, uint256 _membersLimit, address _manager) external;
}
