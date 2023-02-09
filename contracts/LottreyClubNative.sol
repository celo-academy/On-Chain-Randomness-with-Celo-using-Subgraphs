// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interface/IRandom.sol";

contract LottreyClubNative {
    IRandom public constant RANDOMNESS_ADDRESS =
        IRandom(0xdd318EEF001BB0867Cd5c134496D6cF5Aa32311F);

    string public name;
    uint256 public prize;
    uint256 public depositAmount;
    uint256 public membersLimit;

    address public manager;
    address public factory;
    address private _winnerAddress;
    address[] private _membersCounters;

    bool public isLottreyStart = false;

    mapping(address => uint256) private _balance;

    modifier onlyManager() {
        require(
            msg.sender == manager,
            "LottreyClub: Only manager can call this function"
        );
        _;
    }

    event NewRegister(address indexed member, uint256 timestamp);
    event LottreyWinner(
        address indexed winner,
        uint256 prize,
        uint256 timestamp
    );

    constructor() {
        factory = msg.sender;
        _winnerAddress = address(0);
    }

    function initialize(
        string calldata _name,
        uint256 _prize,
        uint256 _deposit,
        uint256 _membersLimit,
        address _manager
    ) external {
        require(
            msg.sender == factory,
            "LottreyClub: Only factory can call this function"
        );
        name = _name;
        prize = _prize;
        depositAmount = _deposit;
        membersLimit = _membersLimit;
        manager = _manager;
    }

    function startLottrey() external onlyManager {
        require(!isLottreyStart, "LottreyClub: Lottrey already started");
        isLottreyStart = true;
    }

    function endLottreyAndDraw() external onlyManager {
        require(isLottreyStart, "LottreyClub: Lottrey not started");
        require(
            _membersCounters.length >= membersLimit,
            "LottreyClub: Not enough members"
        );
        require(
            address(this).balance >= prize,
            "LottreyClub: Not enough balance"
        );
        _drawLottrey();
    }

    function registerMember() external payable {
        require(isLottreyStart, "LottreyClub: Lottrey not started");
        require(_membersCounters.length < membersLimit, "LottreyClub: Full");
        require(_balance[msg.sender] == 0, "LottreyClub: Already registered");
        require(
            msg.value == depositAmount,
            "LottreyClub: Deposit amount not correct");
        _balance[msg.sender] = msg.value;
        _membersCounters.push(msg.sender);
        emit NewRegister(msg.sender, block.timestamp);
    }

    function getMembersTotal() external view returns(uint256) {
        return _membersCounters.length;
    }

    function _drawLottrey() private {
        _winnerAddress = _membersCounters[
            _getRandomNumber() % _membersCounters.length
        ];
        (bool success, ) = _winnerAddress.call{value: prize}("");
        if (success) {
            emit LottreyWinner(_winnerAddress, prize, block.timestamp);
            _resetLottrey();
        } else {
            revert("LottreyClub: Error sending prize to winner");
        }
    }

    function _resetLottrey() private {
        _winnerAddress = address(0);
        _membersCounters = new address[](0);
        isLottreyStart = false;
    }

    function _getRandomNumber() private view returns (uint256) {
        return uint256(RANDOMNESS_ADDRESS.random());
    }
}
