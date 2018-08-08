
pragma solidity ^0.4.18;

import "./vendor/KyberNetwork.sol";
import "./base/math/SafeMath.sol";

contract StakingContract {

using SafeMath for uint96;
using SafeMath for uint;
 
 uint constant  REWARD_PERCENTAGE = 5;
 uint constant  WITHDRAWING_WHILE_ACTIVE_PENALTY = 20;
 
 struct UserStakeData{
    
    uint96 currentStakeAmount;
    uint96 totalSentAmount;
    uint64 stakeUnlockDate;
    uint32 lastRewardRoundWithdrawn;
    mapping(uint32 => uint96) amountsHistory;
 }
 
 struct RewardData{
     
     uint totalReward;
     uint totalEthReceived;
     uint rewardDate;
 }
 
 mapping (address => UserStakeData) userStakes;

 mapping (uint => RewardData) rewards;

 uint32 rewardRoundNumber = 0;
 
 uint public totalEthReceived = 0;
 
 uint public totalTokenLockedAmount = 0;
 
 uint public currentRewardAmount = 0;
  
 uint public lastRewardDistributionDate;

 ERC20 public token ;
  
 KyberNetworkProxy public kyberContract ;
  

constructor(address _tokenAddress, address _kyberContract) public {

        // Check inputs
        require(_tokenAddress != address(0));
        require(_kyberContract != address(0));

        token = ERC20(_tokenAddress);
        kyberContract = KyberNetworkProxy(_kyberContract);
    
}


 function claimRewards() public{
     
     UserStakeData storage data = userStakes[msg.sender];

     for(uint32 i=data.lastRewardRoundWithdrawn; i < rewardRoundNumber; i++ ){
         
         uint96 totalPaidForRound = data.amountsHistory[i];
         
         RewardData dataForRound = rewards[i];
         
         uint reward = totalPaidForRound.div(dataForRound.totalEthReceived).mul(dataForRound.totalReward);
         
         data.currentStakeAmount += uint96(reward);
     }
     
     data.lastRewardRoundWithdrawn = rewardRoundNumber;
     
 }
 
 function withdrawStake() public {
     
     

    UserStakeData storage stakeData = userStakes[msg.sender];
     
    require(stakeData.currentStakeAmount > 0);
     
    token.approve(this, stakeData.currentStakeAmount);
     
    uint amountToWitdraw = stakeData.currentStakeAmount;
     
    if(stakeData.stakeUnlockDate >= now)
        amountToWitdraw  = amountToWitdraw.sub(amountToWitdraw.mul(WITHDRAWING_WHILE_ACTIVE_PENALTY).div(100));
    
    token.transferFrom(this, msg.sender, amountToWitdraw);
     
    totalTokenLockedAmount.sub(stakeData.currentStakeAmount);
    stakeData.currentStakeAmount = 0;
    stakeData.totalSentAmount = 0;
 }

 
 function receive() public payable{
     
     
    require(msg.value > 0);
    
    UserStakeData storage data = userStakes[msg.sender];

    data.totalSentAmount += uint96(msg.value);
    data.amountsHistory[rewardRoundNumber] =  data.totalSentAmount;

    data.stakeUnlockDate = uint64(now);
 
 }
 
 function calculateGlobalStakeSize() view public returns(uint size){
     
     size = token.balanceOf(this) - totalTokenLockedAmount;
 }
 
 
 function generateReward() public {
     
    var currentGlobalStakeSize = calculateGlobalStakeSize();
    
    var rewardAmount = currentGlobalStakeSize.mul(REWARD_PERCENTAGE).div(100);
    
    RewardData storage rewardData = rewards[rewardRoundNumber];
    
    rewardData.totalReward = rewardAmount;
    rewardData.totalEthReceived = totalEthReceived;
    rewardData.rewardDate = now;
    
    totalTokenLockedAmount += rewardAmount;
    
    ++rewardRoundNumber;
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
 
 
 function getUnclaimedRewards() public view returns(uint total, uint numOfUnpaidRewards){
     
         
     UserStakeData storage data = userStakes[msg.sender];
     
     

     for(uint32 i=data.lastRewardRoundWithdrawn; i < rewardRoundNumber; i++ ){
         
         uint96 totalPaidForRound = data.amountsHistory[i];
         
         RewardData dataForRound = rewards[i];
         
         uint reward = totalPaidForRound.div(dataForRound.totalEthReceived).mul(dataForRound.totalReward);
         
         total+=reward;
     }
     
     numOfUnpaidRewards = rewardRoundNumber-data.lastRewardRoundWithdrawn;
 }
 
 
 function getCurrentRewardRound() public view returns(uint32){
     
     return rewardRoundNumber;
 }

  
   
function getTotalRewardsForRound(uint32 index) public view returns (uint rewardAmount, uint totalEthReceived){
    
    require(index < rewardRoundNumber);
    
    RewardData storage data = rewards[index];
    
    rewardAmount = data.totalReward;
    totalEthReceived = data.totalEthReceived;
}

 function getUserStakeData() public view returns (uint96 stake, uint96 total, uint64 unlockDate){
 
    UserStakeData storage stakeData = userStakes[msg.sender];
    
    stake = stakeData.currentStakeAmount;
    total = stakeData.totalSentAmount;
    unlockDate = stakeData.stakeUnlockDate;
     
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