/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-ganache");
//require("./tasks");
require("hardhat-deploy");

require("dotenv").config();

const PRIVATE_KEY_MOONBASE = process.env.PRIVATE_KEY_MOONBASE;
const MOONBASE_RPC_URL = process.env.MOONBASE_RPC_URL;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

module.exports = {
  solidity: "0.8.15",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    //adding moonbase alpha, using blast for rpc and .env file to store.
    moonbase: {
      url: MOONBASE_RPC_URL,
      accounts: [PRIVATE_KEY_MOONBASE],
      saveDeployments: true,
      chainId: 1287,
    },
  },
};
