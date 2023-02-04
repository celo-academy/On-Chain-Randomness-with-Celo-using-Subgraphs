// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ILottreyClub {
    event NewRegister(address indexed member, uint256 timestamp);
    event NewUnregister(address indexed member, uint256 timestamp);
    event LottreyWinner(address indexed winner, uint256 prize, uint256 timestamp);


    function getMembersTotal() external view returns (uint256);

    function initialize(string calldata _name, uint256 _prize, uint256 _deposit, uint256 _membersLimit, address _manager) external;

    function startLottrey() external;

    function endLottrey() external;

    function resetLottrey() external;

    function drawLottrey() external;

    function register() external payable;

    function unregister() external;
}
