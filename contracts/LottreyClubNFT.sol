// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IRandom.sol";


contract LottreyClubNFT {
    IRandom public constant RANDOMNESS_ADDRESS =
        IRandom(0xdd318EEF001BB0867Cd5c134496D6cF5Aa32311F);
    
    string public name;
    uint256 public ticketPrice;
    uint256 public membersLimit;
    uint256 private _tokenIds;

    address public manager;
    address public factory;
    address private _prizeAddress;
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

    function initialize(string calldata _name, uint256 _ticketPrice, uint256 _membersLimit, address _manager) external {
        require(msg.sender == factory, "LottreyClub: Only factory can call this function");
        name = _name;
        ticketPrice = _ticketPrice;
        membersLimit = _membersLimit;
        manager = _manager;
    }

    function managerClaimBalance() external payable onlyManager {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "LottreyClub: Transfer failed.");
    }

    function startLottreyAndSetPrize(address _nftAddress, uint256 _tokenId) external onlyManager {
        require(!isLottreyStart, "LottreyClub: Lottrey already started");
        require(_nftAddress != address(0), "LottreyClub: NFT address can't be zero");
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        _prizeAddress = _nftAddress;
        _tokenIds = _tokenId;
        isLottreyStart = true;
    }

    function endLottreyAndDraw() external onlyManager {
        require(isLottreyStart, "LottreyClub: Lottrey not started");
        require(_membersCounters.length == membersLimit, "LottreyClub: Not enough members");
        _drawLottrey();
    }

    function registerMember() external payable {
        require(isLottreyStart, "LottreyClub: Lottrey not started");
        require(_membersCounters.length < membersLimit, "LottreyClub: Members limit reached");
        require(msg.value == ticketPrice, "LottreyClub: Wrong amount");
        require(_balance[msg.sender] == 0, "LottreyClub: Already registered");
        _balance[msg.sender] = msg.value;
        _membersCounters.push(msg.sender);
        emit NewRegister(msg.sender, block.timestamp);
    }

    function getMembersTotal() external view returns(uint256) {
        return _membersCounters.length;
    }

    function _drawLottrey() private {
        _winnerAddress = _membersCounters[_getRandomNumber() % _membersCounters.length];
        IERC721(_prizeAddress).transferFrom(address(this), _winnerAddress, _tokenIds);
        emit LottreyWinner(_winnerAddress, _tokenIds, block.timestamp);
        _resetLottrey();
    }

    function _resetLottrey() private {
        _tokenIds = 0;
        _prizeAddress = address(0);
        _winnerAddress = address(0);
        _membersCounters = new address[](0);
        isLottreyStart = false;
    }

    function _getRandomNumber() private view returns(uint256) {
        return uint256(
            RANDOMNESS_ADDRESS.random()
        );
    }
}