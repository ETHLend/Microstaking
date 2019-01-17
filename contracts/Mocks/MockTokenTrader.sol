
pragma solidity ^0.4.18;

import "../interfaces/ITokenTrader.sol";


contract MockTokenTrader is ITokenTrader{
  

    function tradeTokens(ERC20 _token, address _destinationAddress) external payable returns(uint noOfTokens) {
        
        _token.approve(this, msg.value*(1000));
        _token.transferFrom(this, msg.sender, msg.value*(1000));

    }
	
}