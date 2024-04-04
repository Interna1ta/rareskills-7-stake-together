// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {CloudCoinStaking} from "../src/CloudCoinStaking.sol";
import {CloudCoin} from "../src/CloudCoin.sol";

contract CloudCoinsStakingTest is Test {
    CloudCoinStaking stakingContract;
    CloudCoin coin;
    uint256 public constant TOTAL_COINS = 1_000_000;
    address OWNER = makeAddr("OWNER");
    address BOB = makeAddr("BOB");
    uint256 public constant STAKING_AMOUNT = 100;
    function setUp() public {
        vm.startPrank(OWNER);
        coin = new CloudCoin();
        stakingContract = new CloudCoinStaking(address(coin));
        coin.mint(address(stakingContract), TOTAL_COINS);
        vm.stopPrank();
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
        coin.mint(OWNER, STAKING_AMOUNT);
        coin.approve(address(stakingContract), STAKING_AMOUNT);
        stakingContract.stake(STAKING_AMOUNT);
        stakingContract.unstake();
        vm.stopPrank();
        (uint256 amount, uint256 stakingTime) = stakingContract.getStaker(
            OWNER
        );
        assertEq(amount, 0);
        assertEq(stakingContract.s_totalStaked(), 0);
        assertEq(coin.balanceOf(OWNER), STAKING_AMOUNT);
    }

    function testUnstakeWithoutStaking() public {
        vm.startPrank(OWNER);
        vm.expectRevert();
        stakingContract.unstake();
        vm.stopPrank();
    }

    function testRewardAfterSevenDays() public {
        vm.startPrank(OWNER);
        coin.mint(OWNER, STAKING_AMOUNT);
        coin.approve(address(stakingContract), STAKING_AMOUNT);
        stakingContract.stake(STAKING_AMOUNT);
        vm.warp(block.timestamp + 7 days);
        uint256 expectedReward = (TOTAL_COINS * STAKING_AMOUNT) /
            STAKING_AMOUNT;
        uint256 expectedUnstakedAmount = STAKING_AMOUNT + expectedReward;
        stakingContract.unstake();
        vm.stopPrank();
        assertEq(coin.balanceOf(OWNER), expectedUnstakedAmount);
    }

    function testAliceReward() public {
        uint256 aliceStake = 5000;
        uint256 totalStake = 25000;
        uint256 totalReward = 200000;
        uint256 aliceReward = (TOTAL_COINS * aliceStake) / totalStake;
        uint256 expectedUnstakedAmount = aliceStake + aliceReward;

        vm.startPrank(OWNER);
        coin.mint(OWNER, aliceStake);
        coin.approve(address(stakingContract), aliceStake);
        stakingContract.stake(aliceStake);
        vm.stopPrank();

        vm.prank(OWNER);
        coin.mint(BOB, totalStake - aliceStake);

        vm.startPrank(BOB);
        coin.approve(address(stakingContract), totalStake - aliceStake);
        stakingContract.stake(totalStake - aliceStake);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        vm.prank(OWNER);
        stakingContract.unstake();
        assertEq(coin.balanceOf(OWNER), expectedUnstakedAmount);
    }
}
