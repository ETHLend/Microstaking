
pragma solidity ^0.4.18;

import "./vendor/KyberNetwork.sol";
import "./interfaces/TokenTrader.sol";


contract KyberTokenTrader is TokenTrader{
  
    KyberNetworkProxy public kyberContract ;
    
    constructor(address _kyberContractAddress) public{
        
       kyberContract = KyberNetworkProxy(_kyberContractAddress);
 
    }

    function tradeTokens(ERC20 _token, address _destinationAddress) public payable returns(uint noOfTokens) {
        
        
       uint maxDestAmount = 2**256 - 1;
    
        // Set minConversionRate to 1 
        // A value of 1 will execute the trade according to market price in the time of the transaction confirmation
        uint minConversionRate =   1;
    
    
            // Convert the ETH to ERC20
            noOfTokens = kyberContract.trade.value(msg.value)(
                // Source. From Kyber docs, this value denotes ETH
                ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
                
                // Source amount
                msg.value,
    
                // Destination. 
                _token,
                
                // destAddress: this contract
                _destinationAddress,
                
                // maxDestAmount
                maxDestAmount,
                
                // minConversionRate 
                minConversionRate,
                
                // walletId
                0
            );     
 
        
    }
	
}