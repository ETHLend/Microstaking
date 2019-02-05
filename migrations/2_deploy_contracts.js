var tokenTrader = artifacts.require("KyberTokenTrader");
var stakingContract = artifacts.require("StakingContract");
var stakingLibrary = artifacts.require("StakingLibrary");

module.exports = async function (deployer) {


    deployer.then(async () => {
      
        let tokenAddress = "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03";

        let kyberNetworkProxyAddress = "0x818E6FECD516Ecc3849DAf6845e3EC868087B755";

        await deployer.deploy(tokenTrader, kyberNetworkProxyAddress);

        await tokenTrader.deployed();

        console.log("Deploying staking smart contract, token address: " + tokenAddress + ", trader address: " + tokenTrader.address);

        await deployer.deploy(stakingLibrary);

        await stakingLibrary.deployed();

        await deployer.link(stakingLibrary, stakingContract);

        await deployer.deploy(stakingContract, tokenAddress, tokenTrader.address, "0x0000000000000000000000000000000000000000");

        await stakingContract.deployed;

        console.log("Staking smart contract deployed, address: " + stakingContract.address);
    });
};