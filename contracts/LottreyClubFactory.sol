// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./LottreyClubNative.sol";
import "./LottreyClubStable.sol";

import "./LottreyClubNFT.sol";
import "./interface/ILottreyClubNative.sol";
import "./interface/ILottreyClubStable.sol";

import "./interface/ILottreyClubNFT.sol";

contract LottreyClubFactory {
    uint256 public constant MAX_OWNER_CLUB = 3;
    address[] public allLottreyClubs;

    mapping(address => address) public lottreyClubToManager;
    mapping(address => uint256) private _clubOwnerCounter;

    event ClubNativeCreated(
        address indexed clubNative,
        address indexed manager,
        string name,
        uint256 prize,
        uint256 depositAmount,
        uint256 membersLimit
    );

    event ClubStableCreated(
        address indexed clubStable,
        address indexed prizeAddress,
        address indexed manager,
        string name,
        uint256 prize,
        uint256 depositAmount,
        uint256 membersLimit
    );

    event ClubNftCreated(
        address indexed clubNft,
        address indexed manager,
        string name,
        uint256 ticketPrice,
        uint256 membersLimit
    );

    function createNativeClub(
        string calldata _name,
        uint256 _deposit,
        uint256 _membersLimit
    ) external {
        require(
            _clubOwnerCounter[msg.sender] < MAX_OWNER_CLUB,
            "LottreyClubFactory: You can't create more than 3 clubs"
        );
        require(
            _deposit > 0,
            "LottreyClubFactory: Deposit amount must be greater than 0"
        );
        require(
            _membersLimit > 0,
            "LottreyClubFactory: Members limit must be greater than 0"
        );
        uint256 _prize = _deposit * _membersLimit;
        bytes32 salt = keccak256(
            abi.encodePacked(_name, _deposit, _membersLimit, msg.sender)
        );
        LottreyClubNative club = (new LottreyClubNative){salt: salt}();
        ILottreyClubNative(address(club)).initialize(
            _name,
            _prize,
            _deposit,
            _membersLimit,
            msg.sender
        );
        lottreyClubToManager[msg.sender] = address(club);
        _clubOwnerCounter[msg.sender] += 1;
        allLottreyClubs.push(address(club));
        emit ClubNativeCreated(
            address(club),
            msg.sender,
            _name,
            _prize,
            _deposit,
            _membersLimit
        );
    }

    function createStableClub(
        string calldata _name,
        uint256 _deposit,
        uint256 _membersLimit,
        address _prizeAddress
    ) external {
        require(
            _clubOwnerCounter[msg.sender] < MAX_OWNER_CLUB,
            "LottreyClubFactory: You can't create more than 3 clubs"
        );
        require(
            _deposit > 0,
            "LottreyClubFactory: Deposit amount must be greater than 0"
        );
        require(
            _membersLimit > 0,
            "LottreyClubFactory: Members limit must be greater than 0"
        );
        require(
            _prizeAddress != address(0),
            "LottreyClubFactory: Prize address can't be 0x0"
        );
        uint256 _prize = _deposit * _membersLimit;
        bytes32 salt = keccak256(
            abi.encodePacked(
                _name,
                _deposit,
                _membersLimit,
                _prizeAddress,
                msg.sender
            )
        );
        LottreyClubStable club = (new LottreyClubStable){salt: salt}();
        ILottreyClubStable(address(club)).initialize(
            _name,
            _prize,
            _deposit,
            _membersLimit,
            _prizeAddress,
            msg.sender
        );
        lottreyClubToManager[msg.sender] = address(club);
        _clubOwnerCounter[msg.sender] += 1;
        allLottreyClubs.push(address(club));
        emit ClubStableCreated(
            address(club),
            _prizeAddress,
            msg.sender,
            _name,
            _prize,
            _deposit,
            _membersLimit
        );
    }

    function createNftClub(
        string calldata _name,
        uint256 _ticketPrice,
        uint256 _membersLimit
    ) external {
        require(
            _clubOwnerCounter[msg.sender] < MAX_OWNER_CLUB,
            "LottreyClubFactory: You can't create more than 3 clubs"
        );
        require(
            _ticketPrice > 0,
            "LottreyClubFactory: Ticket price must be greater than 0"
        );
        require(
            _membersLimit > 0,
            "LottreyClubFactory: Members limit must be greater than 0"
        );
        bytes32 salt = keccak256(
            abi.encodePacked(_name, _ticketPrice, _membersLimit, msg.sender)
        );
        LottreyClubNFT club = (new LottreyClubNFT){salt: salt}();
        ILottreyClubNFT(address(club)).initialize(
            _name,
            _ticketPrice,
            _membersLimit,
            msg.sender
        );
        lottreyClubToManager[msg.sender] = address(club);
        _clubOwnerCounter[msg.sender] += 1;
        allLottreyClubs.push(address(club));
        emit ClubNftCreated(
            address(club),
            msg.sender,
            _name,
            _ticketPrice,
            _membersLimit
        );
    }
}
