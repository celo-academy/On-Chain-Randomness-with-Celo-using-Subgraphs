// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interface/IRandom.sol";
import "./interface/ILottreyClub.sol";

contract LottreyClubNative is ILottreyClub {
    string public name;
    uint256 public prize;
    uint256 public depositAmount;
    uint256 public membersLimit;

    address public manager;
    address public factory;
    address private _winerAddress;
    address[] private _membersCounters;

    bool public isLottreyStart = false;
    bool public isLottreyDraw = false;

    mapping(address => uint256) private _membersBalance;

    IRandom public constant RANDOMNESS_ADDRESS =
        IRandom(0x22a4aAF42A50bFA7238182460E32f15859c93dfe);
    
    modifier onlyManager() {
        require(msg.sender == manager, "LottreyClub: Only manager can call this function");
        _;
    }

    constructor() {
        factory = msg.sender;
        _winerAddress = address(0);
    }

    function initialize(string calldata _name, uint256 _prize, uint256 _depositAmount, uint256 _membersLimit, address _manager) external {
        require(msg.sender == factory, "LottreyClub: Only factory can call this function");
        name = _name;
        prize = _prize;
        depositAmount = _depositAmount;
        membersLimit = _membersLimit;
        manager = _manager;
    }

    function startLottrey() external onlyManager {
        require(!isLottreyStart, "LottreyClub: Lottrey already started");
        isLottreyStart = true;
    }

    function endLottrey() external onlyManager {
        require(isLottreyStart, "LottreyClub: Lottrey not started");
        isLottreyStart = false;
    }

    function resetLottrey() external onlyManager {
        require(!isLottreyStart, "LottreyClub: Lottrey not ended");
        require(isLottreyDraw, "LottreyClub: Lottrey not drawed");
        isLottreyDraw = false;
        _winerAddress = address(0);
        _membersCounters = new address[](0);
    }

    function drawLottrey() external onlyManager {
        require(!isLottreyStart, "LottreyClub: Lottrey not ended");
        require(!isLottreyDraw, "LottreyClub: Lottrey already drawed");
        require(address(this).balance == prize, "LottreyClub: Not enough balance");
        isLottreyDraw = true;
        _winerAddress = _membersCounters[_getRandomNumber() % _membersCounters.length];
        (bool success, ) = _winerAddress.call{value: prize}("");
        if (success) {
            emit LottreyWinner(_winerAddress, prize, block.timestamp);
        }else{
            revert("LottreyClub: Transfer failed");
        }
    }

    function register() external payable {
        require(isLottreyStart, "LottreyClub: Lottrey not started");
        require(_membersCounters.length <= membersLimit, "LottreyClub: Members limit reached");
        require(msg.value == depositAmount, "LottreyClub: Deposit amount not correct");
        require(_membersBalance[msg.sender] == 0, "LottreyClub: Already registered");
        _membersBalance[msg.sender] = msg.value;
        _membersCounters.push(msg.sender);
        emit NewRegister(msg.sender, block.timestamp);
    }

    function unregister() external {
        require(isLottreyStart, "LottreyClub: Lottrey not started");
        require(_membersBalance[msg.sender] > 0, "LottreyClub: Not registered");
        uint256 amount = _membersBalance[msg.sender];
        _membersBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (success) {
            emit NewUnregister(msg.sender, block.timestamp);
        }else{
            revert("LottreyClub: Transfer failed");
        }
    }

    function getMembersTotal() external view override returns (uint256) {
        return _membersCounters.length;
    }

    function _getRandomNumber() private view returns(uint256) {
        return uint256(RANDOMNESS_ADDRESS.random());
    }
}
