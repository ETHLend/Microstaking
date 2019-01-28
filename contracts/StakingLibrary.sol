
pragma solidity ^0.4.24;


library StakingLibrary {

  struct UserStakeData{
    
    uint96 currentStakeAmount;
    uint32 lastRewardRoundClaimed;
    uint lastHistoryEntryOnClaimed;
    mapping(uint => UserHistoryData) history;
    uint numOfHistoryEntries;
  }
 
  struct RewardData{
     
    uint totalReward;
    uint totalEthReceived;
    uint64 rewardDate;
  }
  
  struct UserHistoryData{
     
      uint96 amount;
      uint64 date;
      uint16 applicationID;
  }
}