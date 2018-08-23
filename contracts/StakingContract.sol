
pragma solidity ^0.4.18;

import "./vendor/KyberNetwork.sol";
import "./base/math/SafeMath.sol";
import "./base/ownership/Ownable.sol";
import "./interfaces/tokentrader.sol";
import "./StakingLibrary.sol";


contract StakingContract is Ownable {

  using SafeMath for uint96; 
  using SafeMath for uint;

  uint REWARD_PERCENTAGE = 5;
  uint REWARD_ROUND_DURATION = 120; //Reward generation interval in days
  uint WITHDRAWING_WHILE_ACTIVE_PENALTY = 20;
  uint WITHDRAWAL_TIMEFRAME = 30;
 
  mapping (address => StakingLibrary.UserStakeData) userStakes;
  mapping (uint => StakingLibrary.RewardData) rewards;

  uint32 rewardRoundNumber = 0;
 
  uint public totalEthReceived = 0;
 
  uint public totalTokenLockedAmount = 0;
 
  uint public currentRewardAmount = 0;

  
  uint public lastRewardDistributionDate;
  uint public nextRewardDate;

  ERC20 public token;
 
  TokenTrader tokenTrader;
  

  constructor(address _tokenAddress, address _tokenTraderAddress) public {

        // Check inputs
    require(_tokenAddress != address(0));
    require(_tokenTraderAddress != address(0));

    token = ERC20(_tokenAddress);
    tokenTrader = TokenTrader(_tokenTraderAddress);
     
  }


function claimRewards() public{
    
     StakingLibrary.UserStakeData storage userData = userStakes[msg.sender];
     
     uint64 lastActiveDate;
     uint96 lastAmount;

     for(uint32 i=userData.lastRewardRoundClaimed; i < rewardRoundNumber; i++ ){
         
         StakingLibrary.UserHistoryData storage historyEntry = userData.history[i];
         StakingLibrary.RewardData storage currentRewardRoundData= rewards[i];
         
         
         if(historyEntry.amount > 0){
           
            uint reward = uint96(historyEntry.amount.div(currentRewardRoundData.totalEthReceived).mul(currentRewardRoundData.totalReward));
         
            userData.currentStakeAmount += uint96(reward);
            
            lastAmount = historyEntry.amount;
            lastActiveDate = historyEntry.activeDate;
             
         }
         else{
            
            //if amount = 0, user didn't send any fee during the reward round. in that case we need to check if the account was active or not. If still active,
            //we calculate the reward based on the previous round amount, otherwise we send the reward back to the global StakeLibrary

            reward = lastAmount.div(currentRewardRoundData.totalEthReceived).mul(currentRewardRoundData.totalReward);
            
            if(lastActiveDate >= currentRewardRoundData.rewardDate)
                userData.currentStakeAmount += uint96(reward);
            else //send back the reward to the global stake
                totalTokenLockedAmount-=reward;

         }
     }
     
     userData.lastRewardRoundClaimed = rewardRoundNumber;
     
 }
 
 function withdrawStake() public {

    StakingLibrary.UserStakeData storage userData = userStakes[msg.sender];
     
    require(userData.currentStakeAmount > 0);

    require(userData.lastRewardRoundClaimed == rewardRoundNumber);

    require(now <= calculateWithdrawalTimeframeEndDate(userData.activeUntilDate));

    
    uint amountToWitdraw = userData.currentStakeAmount;
     
    if(now <= userData.activeUntilDate)
        amountToWitdraw  = amountToWitdraw.sub(amountToWitdraw.mul(WITHDRAWING_WHILE_ACTIVE_PENALTY).div(100));


    totalTokenLockedAmount=totalTokenLockedAmount.sub(userData.currentStakeAmount);
    totalEthReceived=totalEthReceived.sub(userData.totalSentAmount);
 
    
    userData.currentStakeAmount = 0;
    userData.totalSentAmount = 0;
    userData.activeUntilDate = 0;

    token.approve(this, amountToWitdraw);
    token.transferFrom(this, msg.sender, amountToWitdraw);
     
 }

 
  function receive() external payable{
 
    require(msg.value > 0);
    
    StakingLibrary.UserStakeData storage userData = userStakes[msg.sender];

    if(userData.totalSentAmount == 0)
        userData.lastRewardRoundClaimed = rewardRoundNumber;
        
    userData.totalSentAmount += uint96(msg.value);
    userData.activeUntilDate = uint64(now + 90 days);

    StakingLibrary.UserHistoryData storage historyEntry = userData.history[rewardRoundNumber];
    
    historyEntry.amount = userData.totalSentAmount;
    historyEntry.activeDate = userData.activeUntilDate;
   
 }
 
  function calculateGlobalStakeSize() public view returns(uint size){
     
    size = token.balanceOf(this) - totalTokenLockedAmount;
  
  }
 

  function generateReward() public {
    
    require(now >= nextRewardDate);
    
    if(address(this).balance > 0) //convert has to be called before generateReward
      convert();

    uint currentGlobalStakeSize = calculateGlobalStakeSize();
    
    uint rewardAmount = currentGlobalStakeSize.mul(REWARD_PERCENTAGE).div(100);
    
    StakingLibrary.RewardData storage rewardData = rewards[rewardRoundNumber];
    
    rewardData.totalReward = rewardAmount;
    rewardData.totalEthReceived = totalEthReceived;
    rewardData.rewardDate = now;
    
    totalTokenLockedAmount += rewardAmount;
    
    ++rewardRoundNumber;
    nextRewardDate = calculateNextRewardDate();
    
  } 
 

  function convert() public{


    uint currentBalance = address(this).balance;

    tokenTrader.tradeTokens.value(currentBalance)(token, this);

    totalEthReceived = totalEthReceived.add(currentBalance);
    
  }
 
 
  function getUnclaimedRewards() public view returns(uint total, uint numOfUnpaidRewards){
     
         
    StakingLibrary.UserStakeData storage data = userStakes[msg.sender];
     
    for(uint32 i = data.lastRewardRoundClaimed; i < rewardRoundNumber; i++ ){
         
         
      StakingLibrary.UserHistoryData storage historyEntry = data.history[i];
         
      StakingLibrary.RewardData storage dataForRound = rewards[i];
         
      uint reward = historyEntry.amount.div(dataForRound.totalEthReceived).mul(dataForRound.totalReward);

      total = total.add(reward);

    }
     
    numOfUnpaidRewards = rewardRoundNumber-data.lastRewardRoundClaimed;
  }
 
 
 function getCurrentRewardRound() public view returns(uint32){
     
     return rewardRoundNumber;
 }

  
   
function getTotalRewardsForRound(uint32 index) public view returns (uint rewardAmount, uint ethReceived){
    
    require(index < rewardRoundNumber);
    
    StakingLibrary.RewardData storage data = rewards[index];
    
    rewardAmount = data.totalReward;
    ethReceived = data.totalEthReceived;
}

 function getUserStakeData() public view returns (uint96 stake, uint96 total, uint64 activeUntilDate){
 
    StakingLibrary.UserStakeData storage stakeData = userStakes[msg.sender];
    
    stake = stakeData.currentStakeAmount;
    total = stakeData.totalSentAmount;
    activeUntilDate = stakeData.activeUntilDate;
     
 }


  function calculateWithdrawalTimeframeEndDate(uint activeUntilDate) internal view  returns(uint){
      return activeUntilDate +(60*60*24*REWARD_ROUND_DURATION);
  }

  function calculateNextRewardDate() internal view returns(uint){
      
      uint currentDate = now;

      return currentDate+(60*60*24*REWARD_ROUND_DURATION);
  }


  //contract management functions

  function setRewardRoundDuration(uint duration) onlyOwner public {

      REWARD_ROUND_DURATION = duration;
  }

  function setRewardPercentage(uint percentage) onlyOwner public {

      require(percentage <= 100);

      REWARD_PERCENTAGE = percentage;
  }

}