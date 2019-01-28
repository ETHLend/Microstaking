
pragma solidity ^0.4.24;

import "./vendor/KyberNetwork.sol";
import "./base/math/SafeMath.sol";
import "./base/ownership/Ownable.sol";
import "./interfaces/IStakingContract.sol";
import "./interfaces/ITokenTrader.sol";
import "./interfaces/IRewardCalculator.sol";
import "./StakingLibrary.sol";


contract StakingContract is Ownable, IStakingContract {

  using SafeMath for uint96; 
  using SafeMath for uint;


  /*********TEST PARAMETERS*********/
  uint REWARD_ROUND_DURATION = 1 hours; //Reward generation interval in days
  /**********************************/
  
  /********PRODUCTION PARAMETERS*****/
  //uint REWARD_ROUND_DURATION = 120 days; //Reward generation interval in days
  /**********************************/
  
  uint REWARD_PERCENTAGE = 5;
  
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
 
  ITokenTrader tokenTrader;
  IRewardCalculator rewardCalculator;
  

  constructor(address _tokenAddress, address _tokenTraderAddress, address _rewardCalculator) public {

        // Check inputs
    require(_tokenAddress != address(0));
    require(_tokenTraderAddress != address(0));

    token = ERC20(_tokenAddress);
    tokenTrader = ITokenTrader(_tokenTraderAddress);
    rewardCalculator = IRewardCalculator(_rewardCalculator);
    nextRewardDate = calculateNextRewardDate();
     
  }
  
 function setTokenTrader(address _tokenTrader) public onlyOwner {
     
     tokenTrader = ITokenTrader(_tokenTrader);
 }

 function setRewardCalculator(address _rewardCalculator) public onlyOwner {
     
     rewardCalculator = IRewardCalculator(_rewardCalculator);
 }


function claimRewards() public returns(uint){
    
     StakingLibrary.UserStakeData storage userData = userStakes[msg.sender];

     uint96 pendingReward = rewardCalculator.calculateReward(msg.sender);
     
     
     userData.currentStakeAmount += pendingReward;
     userData.lastHistoryEntryOnClaimed = userData.numOfHistoryEntries-1;
 
     userData.lastRewardRoundClaimed = rewardRoundNumber;

    return userData.currentStakeAmount;   
 }
 
 function withdrawStake() public {

    StakingLibrary.UserStakeData storage userData = userStakes[msg.sender];
     
    require(userData.currentStakeAmount > 0);

    require(userData.lastRewardRoundClaimed == rewardRoundNumber);
    
    require(rewardCalculator.canUserWithdraw(msg.sender));

    uint amountToWitdraw = userData.currentStakeAmount;

    totalTokenLockedAmount=totalTokenLockedAmount.sub(userData.currentStakeAmount);

    userData.currentStakeAmount = 0;
    
    token.approve(this, amountToWitdraw);

    token.transferFrom(this, msg.sender, amountToWitdraw);

     
 }

 
  function receive(address _sender, uint16 _applicationID) external payable {
 
    require(msg.value > 0);
    
     StakingLibrary.UserStakeData storage userData = userStakes[_sender];
  
    StakingLibrary.UserHistoryData storage historyEntry = userData.history[userData.numOfHistoryEntries];
    
    historyEntry.amount = uint96(msg.value);
    historyEntry.date = uint64(block.timestamp);
    historyEntry.applicationID = _applicationID;

    ++userData.numOfHistoryEntries;
  
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
    rewardData.rewardDate = uint64(block.timestamp);
    
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
     
  
    total = data.currentStakeAmount + rewardCalculator.calculateReward(msg.sender);
     
    numOfUnpaidRewards = rewardRoundNumber-data.lastRewardRoundClaimed;
  }
 
 
 function getCurrentRewardRound() public view returns(uint32){
     
     return rewardRoundNumber;
 }

 function getRewardRoundDate(uint rewardIndex) public view returns(uint64) {
  
    require(rewardIndex < rewardRoundNumber);

     StakingLibrary.RewardData storage data = rewards[rewardIndex];
          
    return data.rewardDate;
 }

  
   
function getTotalRewardsForRound(uint32 index) public view returns (uint rewardAmount, uint ethReceived){
    
    require(index < rewardRoundNumber);
    
    StakingLibrary.RewardData storage data = rewards[index];
    
    rewardAmount = data.totalReward;
    ethReceived = data.totalEthReceived;
}

 function getUserStakeData(address _user) public view returns (uint96 amount, uint96 lastRewardRoundClaimed, uint lastHistoryEntryOnClaimed, uint numOfHistoryEntries){
 
    StakingLibrary.UserStakeData storage stakeData = userStakes[_user];
    
    amount = stakeData.currentStakeAmount;
    lastRewardRoundClaimed = stakeData.lastRewardRoundClaimed;
    lastHistoryEntryOnClaimed = stakeData.lastHistoryEntryOnClaimed;
    numOfHistoryEntries = stakeData.numOfHistoryEntries;

 }
 

 function getUserHistoryData(address _user, uint index) public view returns (uint96 amount,uint64 date,uint16 applicationID) {
     
       StakingLibrary.UserStakeData storage stakeData = userStakes[_user];

       require(index < stakeData.numOfHistoryEntries );
       
  
       amount = stakeData.history[index].amount;
       date = stakeData.history[index].date;
       applicationID = stakeData.history[index].applicationID;
 }


  function calculateNextRewardDate() internal view returns(uint){
      

      return block.timestamp+REWARD_ROUND_DURATION;
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