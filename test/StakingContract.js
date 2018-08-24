var stakingContract = artifacts.require("StakingContract");


contract(stakingContract,  function(accounts){


    it("Should send eth to the staking contract",() => {

        console.log("balance: "+web3.eth.getBalance(stakingContract.address));

        stakingContract.deployed().then(instance => {

            console.log(web3.eth.getBalance(stakingContract.address));

            stakingContract.receive({from: web3.eth.accounts[0], gas: 3000000, value: web3.toWei(1)}).then( () => {

      
            });



        });
    });
});
