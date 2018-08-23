![Optional Text](../master/assets/header.png)
# ETHLend Microstaking economy model

## Disclaimer
This is a highly experimental software component. It can be subjected to bugs and will likely evolve significantly over time. Use at your own risk.

## License
All the material in this repository is released under the CC0 (Creative Common) license. 

## Introduction

This repo contains the ETHLend microstaking smart contracts. The readme  describes the functionalities of the contracts involved and the basic flow of operation.

## Generic description of the model

Microstaking is a new approach to manage the economy of a token and provides a new low velocity approach for potentially any ERC20 token used in the context of distributed applications on the ethereum blockchain. For further information on the idea behind this implementation please refer to the following medium post: <link to the post here>

### How it works

The idea behind microstaking is to let users interact with the token in a seamless way to obtain the rights to use the distributed application. It can be assimilated to the process of purchasing a tiket to access a service, using the application currency (token) as a medium. The amount to be paid is calculated off chain by the application itself, and must keep into consideration the gas costs of using the solution to avoid eccessive costs on the user side. The ticket will actually be purchased using ETH as medium, and the staking smart contract will take charge of converting the paid tickets to ERC20 using a trader smart contract. The default implementation for the LEND token uses Kyber but the trader can be replaced at any time into the staking smart contract if other trading solutions are preferred.
The ERC20 into the smart contract will periodically be redistributed to the users of the dapp in a decentralized way. Hereafter we present a more in depth analysis of the process and a description of the API.

#### 1. Collecting, converting and staking the payments

![Optional Text](../master/assets/collecting.png)

