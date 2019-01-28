var token = artifacts.require("MockERC20");
var tokenTrader = artifacts.require("MockTokenTrader");
var stakingContract = artifacts.require("StakingContract");
var stakingLibrary = artifacts.require("StakingLibrary");

module.exports = async function (deployer) {


    deployer.then(async () => {
        let tokenAddress = "0xb5223aa2443361994ed9d786308dffceefb8d20b";

        await deployer.deploy(tokenTrader);

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