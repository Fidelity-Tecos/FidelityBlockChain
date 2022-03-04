require('dotenv').config();
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const { API_URL, PRIVATE_KEY } = process.env;
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.10"
      }
    ]
  },
  defaultNetwork: "hardhat",
   networks: {
      hardhat: {},
      ropsten: {
         url: "https://eth-ropsten.alchemyapi.io/v2/4pbHvJfI7rlwnPysxdf6q8rR8M5Ny-IK",
         accounts: ["af17118d278dd2d92f13b9ce6375410c9fd0e3515ca94c09ef1689e15a9971eb"]
      }
   },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
