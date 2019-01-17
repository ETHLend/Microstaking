pragma solidity ^0.4.24;

interface IRewardCalculator {

    function calculateReward(address _user) external returns(uint96);
    function canUserWithdraw(address _user) external returns(bool);
} 