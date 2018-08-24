var token = artifacts.require("MockERC20");
var tokenTrader = artifacts.require("MockTokenTrader");
var stakingContract = artifacts.require("StakingContract");
var stakingLibrary = artifacts.require("StakingLibrary");

module.exports = function (deployer) {

    deployer.deploy(token).then(() => {

        deployer.deploy(tokenTrader).then(() => {

            console.log("Deploying staking smart contract, token address: " + token.address + ", trader address: " + tokenTrader.address);


            deployer.deploy(stakingLibrary).then(() => {

                deployer.link(stakingLibrary, stakingContract);

                deployer.deploy(stakingContract, token.address, tokenTrader.address).then(() => {

                    console.log("Staking smart contract deployed, address: " + stakingContract.address);
                });
            });
        });

    });
};