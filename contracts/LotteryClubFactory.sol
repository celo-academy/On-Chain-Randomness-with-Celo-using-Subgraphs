// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LotteryClubToken.sol";
import "./LotteryClubNFT.sol";
import "./interface/ILotteryClubToken.sol";
import "./interface/ILotteryClubNFT.sol";

contract LotteryClubFactory {
    using SafeMath for uint256;

    bytes32 public constant TOKEN_TYPEHASH =
        0x96706879d29c248edfb2a2563a8a9d571c49634c0f82013e6f5a7cde739d35d4;
    bytes32 public constant NFT_TYPEHASH =
        0x9c4138cd0a1311e4748f70d0fe3dc55f0f5f75e0f20db731225cbc3b8914016a;

    mapping(address => bool) private _clubStatus;

    event NewClub(
        address indexed club,
        string name,
        uint256 deposit,
        uint256 membersLimit,
        uint256 reward,
        address rewardAddress,
        address manager,
        bytes32 typeHash
    );

    function clubToken(
        string calldata name_,
        uint256 deposit_,
        uint256 membersLimit_,
        address rewardAddress_
    ) external {
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
            "LotteryClubFactory: Reward address must be not zero address"
        );
        (uint256 reward_, uint256 managerFee_) = _calculateFee(
            deposit_,
            membersLimit_
        );
        bytes32 salt = keccak256(
            abi.encodePacked(
                name_,
                deposit_,
                membersLimit_,
                reward_,
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
        _clubStatus[address(club)] = true;
        emit NewClub(
            address(club),
            name_,
            deposit_,
            membersLimit_,
            reward_,
            rewardAddress_,
            msg.sender,
            TOKEN_TYPEHASH
        );
    }

    function clubNFT(
        string calldata _name,
        uint256 _deposit,
        uint256 _membersLimit
    ) external {
        require(
            _deposit > 0,
            "LotteryClubFactory: Deposit must be greater than 0"
        );
        require(
            _membersLimit > 0,
            "LotteryClubFactory: Members limit must be greater than 0"
        );
        bytes32 salt = keccak256(
            abi.encodePacked(_name, _deposit, _membersLimit, msg.sender)
        );
        require(
            !_checkAddress(salt),
            "LotteryClubFactory: Club already exists"
        );
        LotteryClubNFT club = (new LotteryClubNFT){salt: salt}();
        ILotteryClubNFT(address(club)).initialize(
            _name,
            _deposit,
            _membersLimit,
            msg.sender
        );
        _clubStatus[address(club)] = true;
        emit NewClub(
            address(club),
            _name,
            _deposit,
            _membersLimit,
            0,
            address(0),
            msg.sender,
            NFT_TYPEHASH
        );
    }

    function _calculateFee(uint256 deposit_, uint256 membersLimit_)
        private
        pure
        returns (uint256 reward_, uint256 managerFee_)
    {
        uint256 baseReward = deposit_.mul(membersLimit_);
        managerFee_ = baseReward.mul(2).div(100);
        reward_ = baseReward.sub(managerFee_);
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
}
