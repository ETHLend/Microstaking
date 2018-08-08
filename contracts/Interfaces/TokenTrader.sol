
pragma solidity ^0.4.18;

import "../base/token/ERC20.sol";


contract TokenTrader{

    function tradeTokens(ERC20 token,address _destinationAddress) public payable returns(uint noOfTokens);
	
}