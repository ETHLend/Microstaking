
pragma solidity ^0.4.24;

import "../base/token/ERC20.sol";


contract ITokenTrader{

    function tradeTokens(ERC20 token,address _destinationAddress) external payable returns(uint noOfTokens);
	
}