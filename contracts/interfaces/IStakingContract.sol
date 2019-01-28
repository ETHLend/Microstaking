pragma solidity ^0.4.24;

interface IStakingContract {

    function receive(address _sender, uint16 _applicationID) external payable;
} 