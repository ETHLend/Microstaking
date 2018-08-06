
pragma solidity ^0.4.18;

import "./vendor/KyberNetwork.sol";
import "./base/math/SafeMath.sol";

contract StakingContract {

using SafeMath for uint96;
using SafeMath for uint;
 
 
 struct UserStakeData{
    
    uint96 currentStakeAmount;
    uint96 sentAmount;
    uint64 stakeUnlockDate;
 }

 constant REWARD_PERCENTAGE = 5;
 constant WITHDRAWING_WHILE_ACTIVE_PENALTY = 20;
 
 mapping (address => UserStakeData) userStakes ;
 address[] public userStakesAddresses;

 uint public totalEthReceived = 0;
 
 uint public totalTokenLockedAmount = 0;
 
 uint public currentRewardAmount = 0;
  
 uint public lastRewardDistributionDate;


 ERC20 public token ;
  
 KyberNetworkProxy public kyberContract ;
  
 
   

function StakingContract(address _tokenAddress, address _kyberContract) public {
        // Check inputs
        require(_tokenAddress != address(0));
        require(_kyberContract != address(0));

        token = ERC20(_tokenAddress);
        kyberContract = KyberNetworkProxy(_kyberContract);
    
}

 function getStakesAddresses() public view returns (address[]) {
     
     return userStakesAddresses;
 }
 
 function getUserStakeData() public view returns (uint96 stake, uint96 total, uint64 unlockDate){
 
    UserStakeData storage stakeData = userStakes[msg.sender];
    
    stake = stakeData.currentStakeAmount;
    total = stakeData.sentAmount;
    unlockDate = stakeData.stakeUnlockDate;
     
 }
 
 function withdrawStake() public {
     
     UserStakeData storage stakeData = UserStakes[msg.sender];
     
     require(stakeData.currentStakeAmount > 0);
     
     token.approve(this, stakeData.currentStakeAmount);
     
     var amountToWitdraw = stakeData.currentStakeAmount;
     
     if(stakeData.stakeUnlockDate >= now)
        amountToWitdraw  = amountToWitdraw - amountToWitdraw.mul(WITHDRAWING_WHILE_ACTIVE_PENALTY).div(100);
     token.transferFrom(this, msg.sender, amountToWitdraw);
     
     stakeData.currentStakeAmount = 
     
 }

 
 function receive() public payable{
     
     
    require(msg.value > 0);
    
    UserStakeData storage data = userStakes[msg.sender];
    
    if(data.sentAmount == 0)
        userStakesAddresses.push(msg.sender);

    data.sentAmount =data.sentAmount + uint96(msg.value);
    data.stakeUnlockDate = uint64(now);
 
 }
 
 function calculateGlobalStackSize() view public returns(uint size){
     
     size = token.balanceOf(this) - totalTokenLockedAmount;
 }
 
 
 function calculateRewards() public {
     
    var currentGlobalStakeSize = calculateGlobalStackSize();
    
    var currentRewardAmount = currentGlobalStakeSize.mul(REWARD_PERCENTAGE).div(100);
    
    for(var i =0; i<userStakesAddresses.length; i++){
        
        UserStakeData storage data = userStakes[userStakesAddresses[i]];
        
        var ethPaidPercentage = totalEthReceived.div(data.sentAmount);
        
        var amountToStake = currentRewardAmount.mul(ethPaidPercentage);
        
        currentRewardAmount -= amountToStake;
        
        data.currentStakeAmount += uint96(amountToStake);
        totalTokenLockedAmount += amountToStake;
        
    }
    
    require(currentRewardAmount == 0);
    
     
 } 
 

 function convert() public{

        totalEthReceived=totalEthReceived+this.balance;

        uint ethToConvert = this.balance;
   
        uint maxDestAmount = 2**256 - 1;

        // Set minConversionRate to 1 
        // A value of 1 will execute the trade according to market price in the time of the transaction confirmation
        uint minConversionRate =   1;


        // Convert the ETH to ERC20
        uint convertedTokens = kyberContract.trade.value(ethToConvert)(
            // Source. From Kyber docs, this value denotes ETH
            ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
            
            // Source amount
            ethToConvert,

            // Destination. 
            token,
            
            // destAddress: this contract
            this,
            
            // maxDestAmount
            maxDestAmount,
            
            // minConversionRate 
            minConversionRate,
            
            // walletId
            0
        );     
        

 }
 
 
 
 /*
 function AddTest(uint test1, uint test2, uint test3) public{
     
     
     TestField storage data = addresses[msg.sender];

     data.test1 = test1;
     data.test2 = test2;
     data.test3 = test3;
     data.collateral = CollateralType.LendCollateral;
     
 }
 */
 
 
    
    
}