require("@nomiclabs/hardhat-waffle");
require("dotenv").config({path: "./.env"});

const {MNEMONIC} = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    ganache: {
      url: "http://127.0.0.1:7545",
      accounts: {
        mnemonic: MNEMONIC
      }
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/07875f5ded264d0c9b5bcce6fb782494",
      accounts: {
        mnemonic: MNEMONIC
      }
    }
  },
  solidity: {
    version: "0.8.3",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  }
};

