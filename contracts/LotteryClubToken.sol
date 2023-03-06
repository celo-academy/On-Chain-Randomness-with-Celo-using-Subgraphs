// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IRandom.sol";

contract LotteryClubToken {
    using SafeMath for uint256;

    string public name;
    uint256 public reward;
    uint256 public deposit;
    uint256 public membersLimit;
    uint256 private _managerFee;
    uint256 private constant FEE_PERCENT = 2;

    address public rewardAddress;
    address public winer;
    address public manager;
    address public factory;
    address[] private _membersCounters;

    bool public lotteryStatus = false;

    IRandom private constant RANDOMNESS_ADDRESS =
        IRandom(0xdd318EEF001BB0867Cd5c134496D6cF5Aa32311F);

    mapping(address => uint256) private _userDeposit;

    modifier onlyManager() {
        require(
            msg.sender == manager,
            "LotteryClubToken: Only manager can call this function"
        );
        _;
    }

    event RewardUpdate(
        uint256 reward_,
        uint256 deposit_,
        uint256 membersLimit_
    );

    event Winer(address indexed winer_);

    constructor() {
        factory = msg.sender;
        winer = address(0);
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
            msg.sender == factory,
            "LotteryClubToken: Only factory can call this function"
        );
        name = name_;
        reward = reward_;
        deposit = deposit_;
        membersLimit = membersLimit_;
        _managerFee = managerFee_;
        rewardAddress = rewardAddress_;
        manager = manager_;
    }

    function setDeposit(uint256 deposit_) external onlyManager {
        require(!lotteryStatus, "LotteryClubToken: Lottery is running");
        require(
            deposit_ > 0,
            "LotteryClubToken: Deposit must be greater than 0"
        );
        deposit = deposit_;
        _updateReward();
    }

    function setMembersLimit(uint256 membersLimit_) external onlyManager {
        require(!lotteryStatus, "LotteryClubToken: Lottery is running");
        require(
            membersLimit_ > 0,
            "LotteryClubToken: Members limit must be greater than 0"
        );
        membersLimit = membersLimit_;
        _updateReward();
    }

    function claimFee() external onlyManager {
        require(!lotteryStatus, "LotteryClubToken: Lottery is running");
        require(
            _managerFee > 0,
            "LotteryClubToken: Manager fee is 0"
        );
        _managerFee = 0;
        IERC20(rewardAddress).transfer(manager, _managerFee);
    }

    function start() external onlyManager {
        require(!lotteryStatus, "LotteryClubToken: Lottery is running");
        lotteryStatus = true;
        _reset();
    }

    function draw() external onlyManager {
        require(lotteryStatus, "LotteryClubToken: Lottery is not running");
        require(
            _membersCounters.length >= membersLimit,
            "LotteryClubToken: Not enough members"
        );
        require(IERC20(rewardAddress).balanceOf(address(this)) >= reward, "LotteryClubToken: Not enough reward");
        lotteryStatus = false;
        winer = _membersCounters[_getRandomNumber() % _membersCounters.length];
        IERC20(rewardAddress).transfer(winer, reward);
        emit Winer(winer);
    }

    function register() external {
        require(lotteryStatus, "LotteryClubToken: Lottery is not running");
        require(
            _membersCounters.length < membersLimit,
            "LotteryClubToken: Members limit reached"
        );
        require(
            _userDeposit[msg.sender] == 0,
            "LotteryClubToken: You are already registered"
        );
        IERC20(rewardAddress).transferFrom(msg.sender, address(this), deposit);
        _userDeposit[msg.sender] = deposit;
        _membersCounters.push(msg.sender);
    }

    function _updateReward() private {
        uint256 baseReward = deposit.mul(membersLimit);
        _managerFee = baseReward.mul(FEE_PERCENT).div(100);
        reward = baseReward.sub(_managerFee);
        emit RewardUpdate(reward, deposit, membersLimit);
    }

    function _reset() private {
        winer = address(0);
        for (uint256 i = 0; i < _membersCounters.length; i++) {
            _userDeposit[_membersCounters[i]] = 0;
        }
        _membersCounters = new address[](0);
    }

    function _getRandomNumber() private view returns (uint256) {
        return uint256(RANDOMNESS_ADDRESS.random());
    }
}
