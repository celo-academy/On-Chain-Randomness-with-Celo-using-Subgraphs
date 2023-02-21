// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IRandom.sol";

contract LotteryClub {

    using SafeMath for uint256;

    string private _name;
    uint256 private _reward;
    uint256 private _deposit;
    uint256 private _membersLimit;
    uint256 private _managerFee;

    address private _winer;
    address private _manager;
    address private _factory;
    address[] private _membersCounters;

    bool private _isLotteryStatus = false;

    IERC20 private _rewardAddress;
    IRandom private constant RANDOMNESS_ADDRESS = IRandom(0xdd318EEF001BB0867Cd5c134496D6cF5Aa32311F);

    mapping(address => uint256) private _userDeposit;

    modifier onlyManager() {
        require(msg.sender == _manager);
        _;
    }

    event Winer(address indexed club_, address indexed winer_, uint256 reward_, uint256 timestamp_);
    event Register(address indexed club_, address indexed members_, uint256 timestamp_);
    event Reward(address indexed club_, uint256 reward_, uint256 timestamp_);

    constructor() {
        _factory = msg.sender;
        _winer = address(0);
    }

    function initialize(
        string calldata name_,
        uint256 reward_,
        uint256 deposit_,
        uint256 membersLimit_,
        uint256 managerFee_,
        address manager_,
        address rewardAddress_
    ) external {
        require(msg.sender == _factory);
        _name = name_;
        _reward = reward_;
        _deposit = deposit_;
        _membersLimit = membersLimit_;
        _managerFee = managerFee_;
        _manager = manager_;
        _rewardAddress = IERC20(rewardAddress_);
        
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function deposit() external view returns(uint256) {
        return _deposit;
    }

    function reward() external view returns(uint256) {
        return _reward;
    }

    function winer() external view returns(address) {
        return _winer;
    }

    function membersLimit() external view returns(uint256) {
        return _membersLimit;
    }

    function membersTotal() external view returns(uint256) {
        return _membersCounters.length;
    }

    function manager() external view returns(address) {
        return _manager;
    }

    function factory() external view returns(address) {
        return _factory;
    }

    function rewardAddress() external view returns(address) {
        return address(_rewardAddress);
    }

    function lotteryStart() external view returns(bool) {
        return _isLotteryStatus;
    }

    function start() external onlyManager {
        require(!_isLotteryStatus);
        _isLotteryStatus = true;
        _reset();
    }

    function finishAndDraw() external onlyManager {
        require(_isLotteryStatus);
        require(_membersCounters.length == _membersLimit);
        _isLotteryStatus = false;
        _winer = _membersCounters[_getRandomNumber() % _membersCounters.length];
        _rewardAddress.transfer(_winer, _reward);
        emit Winer(address(this), _winer, _reward, block.timestamp);
    }

    function register() external {
        require(_isLotteryStatus);
        require(_membersCounters.length < _membersLimit);
        require(_userDeposit[msg.sender] == 0);
        _userDeposit[msg.sender] = _deposit;
        _rewardAddress.transferFrom(msg.sender, address(this), _deposit);
        _membersCounters.push(msg.sender);
        emit Register(address(this), msg.sender, block.timestamp);
    }

    function _reset() private {
        _winer = address(0);
        _membersCounters = new address[](0);
    }

    function _update() private {
        uint256 baseReward = _deposit.mul(_membersLimit);
        uint256 managerFee = baseReward.div(100).mul(_managerFee);
        _reward = baseReward - managerFee;
        emit Reward(address(this), _reward, block.timestamp);
    }

    function _getRandomNumber() private view returns(uint256) {
        return uint256(RANDOMNESS_ADDRESS.random());
    }    
}