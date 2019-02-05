const HDWalletProvider = require('truffle-hdwallet-provider');

mnemonic = "congress push dog erosion attend distance virus embody fiction scheme puzzle letter";

//mnemonic = "heavy entry bone system elbow cost misery artwork inner pet suit secret";

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 6700000,
      gasPrice: 1
    },

    //My own Kovan instance
    localnode: {
      host: "localhost",
      port: 8545,
      network_id: "42",
      gas: 50000000,
      gasPrice: 100000000000
    },


    kovan: {
      provider: function () {
        return new HDWalletProvider(mnemonic, "https://kovan.infura.io/nq321ByKuruIz2XqTGd5");
      },
      network_id: '42',
      gas: 8000000,
      gasPrice: 7000000000 //7 GWei
    },

    mainnet: {
      provider: function () {
        return new HDWalletProvider(mnemonic, "https://kovan.infura.io/nq321ByKuruIz2XqTGd5");
      },
      network_id: '1',
      gas: 3000000,
      gasPrice: 7000000000 //7 GWei
    },


  }
}