// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {CloudCoinStaking} from "../src/CloudCoinStaking.sol";
import {CloudCoin} from "../src/CloudCoin.sol";

contract CloudCoinsStakingTest is Test {
    CloudCoinStaking stakingContract;
    CloudCoin coin;
    address OWNER = makeAddr("OWNER");
    uint256 public constant STAKING_AMOUNT = 100;
    function setUp() public {
        vm.prank(OWNER);
        coin = new CloudCoin();
        stakingContract = new CloudCoinStaking(address(coin));
    }

    function testStake() public {
        vm.startPrank(OWNER);
        coin.mint(OWNER, STAKING_AMOUNT);
        coin.approve(address(stakingContract), STAKING_AMOUNT);
        assertEq(
            coin.allowance(OWNER, address(stakingContract)),
            STAKING_AMOUNT
        );
        stakingContract.stake(STAKING_AMOUNT);
        (uint256 amount, uint256 stakingTime) = stakingContract.getStaker(
            OWNER
        );
        assertEq(amount, STAKING_AMOUNT);
        assertEq(stakingContract.s_totalStaked(), STAKING_AMOUNT);
    }

    function testUnstake() public {
        vm.startPrank(OWNER);
        stakingContract.stake(STAKING_AMOUNT);
        stakingContract.unstake();
        vm.stopPrank();
        (uint256 amount, uint256 stakingTime) = stakingContract.getStaker(
            OWNER
        );
        assertEq(amount, 0);
        assertEq(stakingContract.s_totalStaked(), 0);
    }
}
