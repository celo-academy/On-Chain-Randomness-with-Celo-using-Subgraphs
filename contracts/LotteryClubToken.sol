// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IRandom.sol";

contract LotteryClubToken {
    using SafeMath for uint256;

    string private _name;
    uint256 private _reward;
    uint256 private _deposit;
    uint256 private _membersLimit;
    uint256 private _managerFee;
    uint256 private _feePercent;

    address private _rewardAddress;
    address private _winer;
    address private _manager;
    address private _factory;
    address[] private _membersCounters;

    bool private _isLotteryStatus = false;

    IRandom private constant RANDOMNESS_ADDRESS =
        IRandom(0xdd318EEF001BB0867Cd5c134496D6cF5Aa32311F);

    mapping(address => uint256) private _userDeposit;

    modifier onlyManager() {
        require(
            msg.sender == _manager,
            "LotteryClubToken: Only manager can call this function"
        );
        _;
    }

    event Winer(address indexed winer_, uint256 reward_, uint256 timestamp_);

    constructor() {
        _factory = msg.sender;
        _winer = address(0);
        _feePercent = 2;
    }

    function initialize(
        string calldata name_,
        uint256 reward_,
        uint256 deposit_,
        uint256 membersLimit_,
        uint256 managerFee_,
        address rewardAddress_,
        address manager_
    ) external {
        require(
            msg.sender == _factory,
            "LotteryClubToken: Only factory can call this function"
        );
        _name = name_;
        _reward = reward_;
        _deposit = deposit_;
        _membersLimit = membersLimit_;
        _managerFee = managerFee_;
        _rewardAddress = rewardAddress_;
        _manager = manager_;
    }

    function setFeePercent(uint256 feePercent_) external {
        require(
            msg.sender == _factory,
            "LotteryClubToken: Only factory can call this function"
        );
        _feePercent = feePercent_;
        _updateReward();
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function reward() external view returns(uint256) {
        return _reward;
    }

    function deposit() external view returns(uint256){
        return _deposit;
    }

    function membersLimit() external view returns(uint256) {
        return _membersLimit;
    }

    function rewardAddress() external view returns(address) {
        return _rewardAddress;
    }

    function manager() external view returns(address) {
        return _manager;
    }

    function factory() external view returns(address) {
        return _factory;
    }

    function setDeposit(uint256 deposit_) external onlyManager {
        require(
            _isLotteryStatus == false,
            "LotteryClubToken: Lottery is active"
        );
        require(
            deposit_ > 0,
            "LotteryClubToken: Deposit must be greater than 0"
        );
        _deposit = deposit_;
        _updateReward();
    }

    function setMembersLimit(uint256 membersLimit_) external onlyManager {
        require(
            _isLotteryStatus == false,
            "LotteryClubToken: Lottery is active"
        );
        require(
            membersLimit_ > 0,
            "LotteryClubToken: Members limit must be greater than 0"
        );
        _membersLimit = membersLimit_;
        _updateReward();
    }

    function claimFee() external onlyManager {
        require(
            _isLotteryStatus == false,
            "LotteryClubToken: Lottery is active"
        );
        require(_managerFee > 0, "LotteryClubToken: Manager fee is 0");
        uint256 amount = _managerFee;
        _managerFee = 0;
        IERC20(_rewardAddress).transfer(msg.sender, amount);
    }

    function start() external onlyManager {
        require(!_isLotteryStatus, "LotteryClubToken: Lottery is active");
        _isLotteryStatus = true;
        _reset();
    }

    function draw() external onlyManager {
        require(_isLotteryStatus, "LotteryClubToken: Lottery is not active");
        require(
            _membersCounters.length >= _membersLimit,
            "LotteryClubToken: Not enough members"
        );
        require(
            address(this).balance >= _reward,
            "LotteryClubToken: Not enough balance"
        );
        _isLotteryStatus = false;
        _winer = _membersCounters[_getRandomNumber() % _membersCounters.length];
        IERC20(_rewardAddress).transfer(_winer, _reward);
        emit Winer(_winer, _reward, block.timestamp);
    }

    function register() external {
        require(_isLotteryStatus, "LotteryClubToken: Lottery is not active");
        require(
            _membersCounters.length < _membersLimit,
            "LotteryClubToken: Members limit is reached"
        );
        require(
            _userDeposit[msg.sender] == 0,
            "LotteryClubToken: You are already registered"
        );
        IERC20(_rewardAddress).transferFrom(msg.sender, address(this), _deposit);
        _userDeposit[msg.sender] = _deposit;
        _membersCounters.push(msg.sender);
    }

    function _reset() private {
        _winer = address(0);
        for (uint256 i = 0; i < _membersCounters.length; i++) {
            _userDeposit[_membersCounters[i]] = 0;
        }
        _membersCounters = new address[](0);
    }

    function _updateReward() private {
        uint256 baseReward = _deposit.mul(_membersLimit);
        _managerFee = baseReward.div(100).mul(_feePercent);
        _reward = baseReward.sub(_managerFee);
    }

    function _getRandomNumber() private view returns (uint256) {
        return uint256(RANDOMNESS_ADDRESS.random());
    }
}
