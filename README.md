![Optional Text](../master/assets/header.png)
# ETHLend Microstaking economy model


Table of contents
=================

<!--ts-->
   * [Disclaimer](#disclaimer)
   * [License](#license)
   * [Introduction](#introduction)
      * [Generic description of the model](#generic-description-of-the-model)
          * [Collecting, converting and staking the payments](#1-collecting-converting-and-staking-the-payments)
          * [Generating, staking and claiming the rewards](#2-generating-staking-and-claiming-the-rewards)
          * [Withdraw the rewards](#3-withdraw-the-rewards)
   * [API Reference](#api-reference)
      * [`StakingLibrary`](#stakinglibrary)
      * [`StakingContract`](#stakingcontract)
        * [`receive()`](#receive)
        * [`convert()`](#convert)
        * [`generateReward()`](#generatereward)
        * [`claimRewards()`](#claimrewards)
        * [`withdrawStake()`](#withdrawstake)
      * [`KyberTokenTrader`](#kybertokentrader)
   * [Basic terminology](#basic-terminology)
   * [GAS Cost analysis](#gas-cost-analysis)
   * [Model simulation examples](#model-simulation-examples)
   
   
<!--te-->


## Disclaimer
This is a highly experimental software component. It can be subjected to bugs and will likely evolve significantly over time. Use at your own risk.

## License
All the material in this repository is released under the CC0 (Creative Common) license. 

## Introduction

This repo contains the ETHLend microstaking smart contracts. The readme  describes the functionalities of the contracts involved and the basic flow of operation.

## Generic description of the model

Microstaking is a new approach to manage the economy of a token and provides a new low velocity approach for potentially any ERC20 token used in the context of distributed applications on the ethereum blockchain. For further information on the idea behind this implementation please refer to the following medium post: <link to the post here>

### How it works

The idea behind microstaking is to let users interact with the token in a seamless way to obtain the rights to use the distributed application. It can be assimilated to the process of purchasing a tiket to access a service, using the application currency (token) as a medium. The amount to be paid is calculated off chain by the application itself, and must keep into consideration the gas costs of using the solution to avoid eccessive costs on the user side. The ticket will actually be purchased using ETH, and the staking smart contract will take charge of converting the paid tickets to ERC20 using a trader smart contract. The default implementation for the LEND token uses Kyber but the trader can be replaced at any time into the staking smart contract if other trading solutions are preferred.
The ERC20 into the smart contract will periodically be redistributed to the users of the dapp in a decentralized way. Hereafter we present a more in depth analysis of the process and a description of the API.

#### 1. Collecting, converting and staking the payments

![Optional Text](../master/assets/collection.png)

First step of the model is collecting the payments. Payments are sent to the staking smart contract (please refere to the `StakingContract` in the [API Reference](#api-reference) section) using the [`receive()`](#receive) function. The function stores the ETH received into the smart contract, and keeps track of the data of the user (total amount of ETH received, active date).
The conversion from ETH to LEND is performed by the [`convert()`](#convert) fuction, that calls the Kyber network `trade()` method through the `KyberTokenTrader` smart contract.

The smart contract keeps track of the global stake deposit through the `calculateGlobalStakeSize()` method.

#### 2. Generating, staking and claiming the rewards

![Optional Text](../master/assets/rewards.png)
The periodic reward is calculated using the [`generateReward()`](#generatereward) method. the call to `generateReward()` marks the start of a new reward round in which users can claim their rewards.  The reward is a percentage of the global stake deposit (the percentage is stored into the `REWARD_PERCENTAGE` contract variable) and it's 5% by default. When a reward is generated, users will need to claim their rewards using the  `claimRewards()` function. Users can wait for multiple reward rounds before claiming their rewards. The total will be calculated automatically using the history data stored for each user.


#### 3. Withdraw the rewards

![Optional Text](../master/assets/withdraw.png)
The withdraw of the stake can be done by the users using the [`withdrawStake()`](#withdrawstake) method. When withdrawing, users will need to take into account in which phase of the staking period they are withdrawing. Withdrawing while still being active on the platform can be subjected to a fee, called withdrawal penalty. The penalty is a percentage of the user's stake, the percentage is stored into the `WITHDRAWING_WHILE_ACTIVE_PENALTY` contract variable. Once a user becomes inactive, he enters in a time period called "withdrawal timeframe". During this period he can withdraw the stake without any penalty. The duration of the withdrawal timeframe is stored into the WITHDRAWAL_TIMEFRAME variable and by default is 30 days. After the withdrawal timeframe, the withdrawal becomes locked and any call to `withdrawStake()` results in a error. The only way for the user to unlock the stake is to become active again by using the platform.

## API Reference

### `StakingLibrary`

Defines the data structures needed to keep track of the reward rounds, the stakes of the users and the history data of the users.

#### 1. `UserStakeData`
Stores the stake size for the users, the total amount of eth sent to the staking smart contract, the active timeframe for the user.  

#### 2. `UserHistoryData`
Stores the historical data (active date and total eth sent) for the user for each reward round in which the use has sent ETH to the smart contract

#### 3. `RewardData`
Keeps track of the rewards data for each reward round.

### `StakingContract`

The core of the model. Keeps track of the ETH received, converts to the ERC20 Token and calculates the rewards for the users. By calling this smart contract users are able to claim their rewards and withdraw their stakes.

 * #### 1. `receive()`
Called whenever payments are collected from the users. It updates the user data increasing the active time window, the total amount of ETH sent to the smart contract and the history data for the current reward round.

 * #### 2. `convert()`
Called to convert the ETH stored into the staking smart contract to the ERC20 token.

 * #### 3. `generateReward()`
Starts a new rewand round. Reward for the round is calculated and data is stored into the `RewardData` mapping.

 * #### 4. `claimRewards()`
Allows the user to claim their rewards for all the reward rounds he has not claimed. Updates the `UserStakeData` accordingly.

 * #### 5. `withdrawStake()`
Called by the users to withdraw their stake. Every time a user withdraws, their current data (total amount of ETH sent, starting reward round, stake size) and the hystorical data is cleared.

### KyberTokenTrader

Converts the ETH sent to ERC20 token

 *#### 1. `tradeTokens()`
 Calls the Kyber network `trade()` function to convert ETH to the target ERC20 token.

## Basic terminology

### Global stake deposit:
Identifies the amount of ERC20 token stored into the smart contract, that is periodically distributed to the users.

* ### Reward round:
  Is one reward period. Rewards can be generated every 90 days by default. For every reward round, every user can claim part of the total reward for the round. The portion of the total reward for each user is proportional to the total amount of ETH he sent to the staking smart contract.

* ### Withdrawal timeframe:


## GAS Cost analysis

## Model simulation examples

