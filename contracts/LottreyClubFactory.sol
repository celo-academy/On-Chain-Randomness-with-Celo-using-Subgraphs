// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./LottreyClubNative.sol";
import "./interface/ILottreyClub.sol";

contract LottreyClubFactory is Ownable {
    uint256 public constant MAX_OWNER_CLUBS = 3;
    address[] public allLottreyClubs;
    mapping(address => address) public lottreyClubByManager;
    mapping(address => uint256) private clubOwnerCounter;

    event ClubNativeCreated
    (
        address indexed clubNative,
        string name,
        uint256 prize,
        uint256 depositAmount,
        uint256 membersLimit,
        address indexed manager
    );

    function createNativeClub(
        string calldata _name,
        uint256 _depositAmount,
        uint256 _membersLimit
    ) external {
        require(
            clubOwnerCounter[msg.sender] < MAX_OWNER_CLUBS,
            "LottreyClubFactory: You can't create more than 3 clubs"
        );
        require(_depositAmount > 0, "LottreyClubFactory: Deposit amount must be greater than 0");
        require(_membersLimit > 0, "LottreyClubFactory: Members limit must be greater than 0");
        bytes32 salt = keccak256(abi.encodePacked(_name, _depositAmount, _membersLimit, msg.sender));
        uint256 _prize = _depositAmount * _membersLimit;
        LottreyClubNative clubNative = (new LottreyClubNative){salt: salt}();
        ILottreyClub(clubNative).initialize(_name, _prize, _depositAmount, _membersLimit, msg.sender);
        clubOwnerCounter[msg.sender] += 1;
        lottreyClubByManager[msg.sender] = address(clubNative);
        allLottreyClubs.push(address(clubNative));
        emit ClubNativeCreated(address(clubNative), _name, _prize, _depositAmount, _membersLimit, msg.sender);
    }
}
