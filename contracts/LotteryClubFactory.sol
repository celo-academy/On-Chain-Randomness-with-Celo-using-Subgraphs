// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IRandom.sol";
import "./interface/ILotteryClub.sol";
import "./interface/ILotteryClubNFT.sol";

import "./LotteryClub.sol";
import "./LotteryClubNFT.sol";

contract LotteryClubFactory {
    using SafeMath for uint256;
    uint256 public constant MAX_OWNER_CLUB = 3;
    uint256 public MANAGER_FEE_PERCENT = 2;

    mapping(address => bool) private _clubStatus;
    mapping(address => uint256) private _clubOwnerCounter;

    event Club(address indexed club_, address indexed manager_, string name_, uint256 reward_, uint256 deposit_, uint256 membersLimit_);
    event ClubNFT(address indexed club_, address indexed manager_, string name_, uint256 deposit_, uint256 membersLimit_);

    function createClub(
        string calldata name_,
        uint256 deposit_,
        uint256 membersLimit_,
        address rewardAddress_
    ) external {
        require(_clubOwnerCounter[msg.sender] <= MAX_OWNER_CLUB);
        require(deposit_ > 0);
        require(membersLimit_ > 0);
        require(rewardAddress_ != address(0));
        (uint256 reward, uint256 managerFee) = _calculateReward(deposit_, membersLimit_);
        bytes32 salt = keccak256(
            abi.encodePacked(name_, deposit_, membersLimit_, rewardAddress_, msg.sender)
        );
        require(!_checkAddress(salt));
        LotteryClub club = (new LotteryClub){salt: salt}();
        ILotteryClub(address(club)).initialize(
            name_,
            reward,
            deposit_,
            membersLimit_,
            managerFee,
            msg.sender,
            rewardAddress_
        );
        _clubStatus[address(club)] = true;
        _clubOwnerCounter[msg.sender] +=1;
        emit Club(
            address(club),
            msg.sender,
            name_,
            reward,
            deposit_,
            membersLimit_
        );
    }

    function createClubNFT(string calldata name_, uint256 deposit_, uint256 membersLimit_) external {
        require(_clubOwnerCounter[msg.sender] <= MAX_OWNER_CLUB);
        require(deposit_ > 0);
        require(membersLimit_ > 0);
        bytes32 salt = keccak256(
            abi.encodePacked(name_, deposit_, membersLimit_, msg.sender)
        );
        require(!_checkAddress(salt));
        LotteryClubNFT club = (new LotteryClubNFT){salt:salt}();
        ILotteryClubNFT(address(club)).initialize(
            name_,
            deposit_,
            membersLimit_,
            msg.sender
        );
        _clubStatus[address(club)] = true;
        _clubOwnerCounter[msg.sender] += 1;
        emit ClubNFT(address(club), msg.sender, name_, deposit_, membersLimit_);
    }

    function _checkAddress(bytes32 salt_) private view returns (bool) {
        address predictAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt_,
                            keccak256(
                                abi.encodePacked(type(LotteryClub).creationCode)
                            )
                        )
                    )
                )
            )
        );
        return _clubStatus[predictAddress];
    }

    function _calculateReward(uint256 deposit_, uint256 membersLimit_)
        private
        view
        returns (uint256 reward_, uint256 managerFee_)
    {
        uint256 baseReward = deposit_.mul(membersLimit_);
        managerFee_ = baseReward.div(100).mul(MANAGER_FEE_PERCENT);
        reward_ = baseReward.sub(managerFee_);
    }
}
