var token = artifacts.require("MockERC20");
var tokenTrader = artifacts.require("MockTokenTrader");
var stakingContract = artifacts.require("StakingContract");

module.exports = async function (deployer) {

    await deployer.deploy(token);

    await deployer.deploy(tokenTrader);

    console.log("Deploying staking smart contract, token address: "+token.address+", trader address: "+tokenTrader.address );

    await deployer.deploy(stakingContract, token.address, tokenTrader.address);


};