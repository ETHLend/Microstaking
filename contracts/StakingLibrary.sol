
pragma solidity ^0.4.24;


library StakingLibrary {

  struct UserStakeData{
    
    uint96 currentStakeAmount;
    uint32 lastRewardRoundClaimed;
    uint lastHistoryEntryOnClaimed;
    UserHistoryData[] history;
  }
 
  struct RewardData{
     
    uint totalReward;
    uint totalEthReceived;
    uint rewardDate;
  }
  
  struct UserHistoryData{
     
      uint96 amount;
      uint64 date;
      uint16 applicationID;
  }
}