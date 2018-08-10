
pragma solidity ^0.4.18;


library StakingLibrary {

  struct UserStakeData{
    
    uint96 currentStakeAmount;
    uint96 totalSentAmount;
    uint64 activeUntilDate;
    uint32 lastRewardRoundClaimed;
    mapping(uint32 => UserHistoryData) history;
  }
 
  struct RewardData{
     
    uint totalReward;
    uint totalEthReceived;
    uint rewardDate;
  }
  
  struct UserHistoryData{
     
      uint96 amount;
      uint64 activeDate;
  }
}