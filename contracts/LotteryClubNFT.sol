// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IRandom.sol";

contract LotteryClubNFT {
    string public name;
    uint256 public reward;
    uint256 public deposit;
    uint256 public membersLimit;

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

    event RewardUpdate(address indexed rewardAddress_, uint256 reward_);
    event LimitAndDepoUpdate(uint256 update_, string name_);
    event Winer(address indexed winer_);

    constructor() {
        factory = msg.sender;
        winer = address(0);
    }

    function initialize(
        string calldata _name,
        uint256 _deposit,
        uint256 _membersLimit,
        address _manager
    ) external {
        require(
            msg.sender == factory,
            "LotteryClubNFT: Only factory can call this function"
        );
        name = _name;
        deposit = _deposit;
        membersLimit = _membersLimit;
        manager = _manager;
    }

    function setMembersLimit(uint256 _membersLimit) external onlyManager {
        require(!lotteryStatus, "LotteryClubNFT: Lottery is already started");
        require(
            _membersLimit > 0,
            "LotteryClubNFT: Members limit must be greater than 0"
        );
        membersLimit = _membersLimit;
        emit LimitAndDepoUpdate(_membersLimit, "membersLimit");
    }

    function setDeposit(uint256 _deposit) external onlyManager {
        require(!lotteryStatus, "LotteryClubNFT: Lottery is already started");
        require(_deposit > 0, "LotteryClubNFT: Deposit must be greater than 0");
        deposit = _deposit;
        emit LimitAndDepoUpdate(_deposit, "deposit");
    }

    function setReward(address _rewardAddress, uint256 _tokenId)
        external
        onlyManager
    {
        require(!lotteryStatus, "LotteryClubNFT: Lottery is already started");
        require(
            rewardAddress == address(0),
            "LotteryClubNFT: Reward already set"
        );
        require(
            _rewardAddress != address(0),
            "LotteryClubNFT: Reward address is zero"
        );
        IERC721(_rewardAddress).transferFrom(msg.sender, address(this), _tokenId);
        rewardAddress = _rewardAddress;
        reward = _tokenId;
        emit RewardUpdate(_rewardAddress, _tokenId);
    }

    function claimFee() external onlyManager {
        require(!lotteryStatus, "LotteryClubNFT: Lottery is already started");
        require(address(this).balance > 0, "LotteryClubNFT: No balance");
        (bool status, ) = msg.sender.call{value: address(this).balance}("");
        require(status, "LotteryClubNFT: Transfer failed");
    }

    function start() external onlyManager {
        require(!lotteryStatus, "LotteryClubNFT: Lottery is already started");
        require(rewardAddress != address(0), "LotteryClubNFT: Reward not set");
        lotteryStatus = true;
        _reset();
    }

    function draw() external onlyManager {
        require(lotteryStatus, "LotteryClubNFT: Lottery is not started");
        require(
            _membersCounters.length >= membersLimit,
            "LotteryClubNFT: Not enough members"
        );
        lotteryStatus = false;
        winer = _membersCounters[_getRandomNumber() % _membersCounters.length];
        _userDeposit[winer] = 0;
        IERC721(rewardAddress).transferFrom(address(this), winer, reward);
        _batchTransfer();
        emit Winer(winer);
    }

    function register() external payable {
        require(lotteryStatus, "LotteryClubNFT: Lottery is not started");
        require(
            msg.value == deposit,
            "LotteryClubNFT: Deposit amount is not correct"
        );
        require(
            _membersCounters.length < membersLimit,
            "LotteryClubNFT: Members limit reached"
        );
        require(
            _userDeposit[msg.sender] == 0,
            "LotteryClubNFT: You are already registered"
        );
        _userDeposit[msg.sender] = msg.value;
        _membersCounters.push(msg.sender);
    }

    function _batchTransfer() private {
        for (uint256 i = 0; i < _membersCounters.length; i++) {
            if (_userDeposit[_membersCounters[i]] > 0) {
                (bool status, ) = _membersCounters[i].call{
                    value: _userDeposit[_membersCounters[i]]
                }("");
                require(status);
            }
        }
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
