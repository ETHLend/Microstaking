
pragma solidity ^0.4.18;

import "../interfaces/TokenTrader.sol";


contract MockTokenTrader is TokenTrader{
  

    function tradeTokens(ERC20 _token, address _destinationAddress) public payable returns(uint noOfTokens) {
        
        _token.approve(this, msg.value*2);
        _token.transferFrom(this, msg.sender, msg.value*2);

    }
	
}