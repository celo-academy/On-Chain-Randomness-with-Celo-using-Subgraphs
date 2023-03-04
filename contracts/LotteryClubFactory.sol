// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LotteryClubToken.sol";

import "./interface/ILotteryClubToken.sol";

contract LotteryClubFactory is Ownable {
    using SafeMath for uint256;

    uint256 private _managerFeePercent;
    uint256 private MAX_OWNER_CLUB = 3;

    mapping(address => uint256) private _clubOwnerCounters;
    mapping(address => bool) private _clubStatus;

    address[] private _allClubAddress;

    event NewClub(
        address indexed clubAddress,
        address indexed owner,
        string name,
        uint256 reward,
        uint256 deposit,
        uint256 membersLimit
    );

    constructor(uint256 managerFee_) {
        _managerFeePercent = managerFee_;
    }

    function createClubToken(
        string calldata name_,
        uint256 deposit_,
        uint256 membersLimit_,
        address rewardAddress_
    ) external {
        require(
            _clubOwnerCounters[msg.sender] <= MAX_OWNER_CLUB,
            "LotteryClubFactory: You can't create more than 3 clubs"
        );
        require(
            deposit_ > 0,
            "LotteryClubFactory: Deposit must be greater than 0"
        );
        require(
            membersLimit_ > 0,
            "LotteryClubFactory: Members limit must be greater than 0"
        );
        require(
            rewardAddress_ != address(0),
            "LotteryClubFactory: Reward address can't be 0x0"
        );
        (uint256 reward_, uint256 managerFee_) = _calculateReward(
            deposit_,
            membersLimit_
        );
        bytes32 salt = keccak256(
            abi.encodePacked(
                name_,
                deposit_,
                membersLimit_,
                rewardAddress_,
                msg.sender
            )
        );
        require(
            !_checkAddress(salt),
            "LotteryClubFactory: Club already exists"
        );
        LotteryClubToken club = (new LotteryClubToken){salt: salt}();
        ILotteryClubToken(address(club)).initialize(
            name_,
            reward_,
            deposit_,
            membersLimit_,
            managerFee_,
            rewardAddress_,
            msg.sender
        );
        _clubOwnerCounters[msg.sender] += 1;
        _clubStatus[address(club)] = true;
        _allClubAddress.push(address(club));

        emit NewClub(
            address(club),
            msg.sender,
            name_,
            reward_,
            deposit_,
            membersLimit_
        );
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
                                abi.encodePacked(
                                    type(LotteryClubToken).creationCode
                                )
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
        managerFee_ = baseReward.div(100).mul(_managerFeePercent);
        reward_ = baseReward.sub(managerFee_);
    }
}
