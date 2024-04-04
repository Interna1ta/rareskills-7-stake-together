// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error CloudCoinStaking__InvalidAmount(string message);
error CloudCoinStaking__AlreadyStaked(string message);
error CloudCoinStaking__NotStaked(string message);

contract CloudCoinStaking {
    uint256 constant TOTAL_COINS = 1_000_000;
    uint256 constant SEVEN_DAYS = 7 days;
    address public immutable i_cloudCoin;

    struct Staker {
        uint256 amount;
        uint256 stakingTime;
    }

    mapping(address => Staker) public s_stakers;
    uint256 public s_totalStaked;

    event Staked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount, uint256 reward);

    constructor(address cloudCoin) {
        i_cloudCoin = cloudCoin;
    }

    function stake(uint256 _amount) external {
        if (_amount <= 0) {
            revert CloudCoinStaking__InvalidAmount("Invalid amount");
        }
        if (s_stakers[msg.sender].amount != 0) {
            revert CloudCoinStaking__AlreadyStaked("Already staked");
        }

        IERC20(i_cloudCoin).transferFrom(msg.sender, address(this), _amount);

        s_stakers[msg.sender].amount = _amount;
        s_stakers[msg.sender].stakingTime = block.timestamp;
        s_totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    function unstake() external {
        if (s_stakers[msg.sender].amount <= 0) {
            revert CloudCoinStaking__NotStaked("Not staked");
        }

        uint256 amount = s_stakers[msg.sender].amount;
        uint256 reward = calculateReward(msg.sender);

        s_stakers[msg.sender].amount = 0;
        s_stakers[msg.sender].stakingTime = 0;
        s_totalStaked -= amount;


        IERC20(i_cloudCoin).transfer(msg.sender, amount + reward);

        emit RewardClaimed(msg.sender, amount, reward);
    }

    function calculateReward(address _staker) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - s_stakers[_staker].stakingTime;
        if (elapsed < SEVEN_DAYS) {
            return 0;
        }
        return (s_stakers[_staker].amount * TOTAL_COINS) / s_totalStaked;
    }

    function totalStaked() external view returns (uint256) {
        return s_totalStaked;
    }

    function getStaker(
        address _staker
    ) external view returns (uint256 amount, uint256 stakingTime) {
        amount = s_stakers[_staker].amount;
        stakingTime = s_stakers[_staker].stakingTime;
    }
}
