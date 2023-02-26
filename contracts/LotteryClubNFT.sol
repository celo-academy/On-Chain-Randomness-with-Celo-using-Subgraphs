// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IRandom.sol";

contract LotteryClubNFT {

    string private _name;
    uint256 private _deposit;
    uint256 private _membersLimit;
    uint256 private _tokenId;

    address private _winer;
    address private _manager;
    address private _factory;
    address[] private _membersCounters;

    bool private _isLotteryStatus = false;

    IERC721 private _rewardAddress;
    IRandom private constant RANDOMNESS_ADDRESS = IRandom(0xdd318EEF001BB0867Cd5c134496D6cF5Aa32311F);

    mapping(address => uint256) private _userDeposit;

    modifier onlyManager() {
        require(msg.sender == _manager);
        _;
    }

    event Register(address indexed club_, address indexed members_, uint256 timestamp_);
    event Winer(address indexed club_, address indexed winer_, uint256 timestamp_);
    constructor() {
        _factory = msg.sender;
        _winer = address(0);
    }

    function initialize(
        string calldata name_,
        uint256 deposit_,
        uint256 membersLimit_,
        address manager_
    ) external {
        require(msg.sender == _factory);
        _name = name_;
        _deposit = deposit_;
        _membersLimit = membersLimit_;
        _manager = manager_;
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function deposit() external view returns(uint256) {
        return _deposit;
    }

    function membersLimit() external view returns(uint256) {
        return _membersLimit;
    }

    function membersTotal() external view returns(uint256) {
        return _membersCounters.length;
    }

    function winer() external view returns(address) {
        return _winer;
    }

    function rewardAddress() external view returns(address) {
        return address(_rewardAddress);
    }

    function manager() external view returns(address) {
        return _manager;
    }

    function factory() external view returns(address) {
        return _factory;
    }

    function clubStatus() external view returns(bool) {
        return _isLotteryStatus;
    }

    function setDeposit(uint256 deposit_) external onlyManager {
        require(!_isLotteryStatus);
        require(deposit_ > 0);
        _deposit = deposit_;
    }

    function setMembersLimit(uint256 membersLimit_) external onlyManager {
        require(!_isLotteryStatus);
        require(membersLimit_ > 0);
        _membersLimit = membersLimit_;
    }

    function start(address rewardAddress_, uint256 tokenId_) external onlyManager {
        require(!_isLotteryStatus);
        require(rewardAddress_ != address(0));
        IERC721(rewardAddress_).transferFrom(msg.sender, address(this), tokenId_);
        _rewardAddress = IERC721(rewardAddress_);
        _tokenId = tokenId_;
        _isLotteryStatus = true;
        _reset();
    }

    function finishAndDraw() external onlyManager {
        require(_isLotteryStatus);
        require(_membersCounters.length == _membersLimit);
        _isLotteryStatus = false;
        _winer = _membersCounters[_getRandomNumber() % _membersCounters.length];
        _userDeposit[_winer] = 0;
        _rewardAddress.transferFrom(address(this), _winer, _tokenId);
        _batchTransfer();
        emit Winer(address(this), _winer, block.timestamp);
    }

    function registerMember() external payable {
        require(_isLotteryStatus);
        require(_membersCounters.length < _membersLimit);
        require(_userDeposit[msg.sender] == 0);
        _userDeposit[msg.sender] = msg.value;
        _membersCounters.push(msg.sender);
        emit Register(address(this), msg.sender, block.timestamp);
    }

    function _batchTransfer() private {
        for(uint i = 0; i < _membersCounters.length; i++) {
            if(_userDeposit[_membersCounters[i]] > 0) {
                (bool status, ) = _membersCounters[i].call{value:_userDeposit[_membersCounters[i]]}("");
                require(status);
            }
        }
    }

    function _reset() private {
        _winer = address(0);
        _membersCounters = new address[](0);
    }

    function _getRandomNumber() private view returns(uint256) {
        return uint256(RANDOMNESS_ADDRESS.random());
    }
}