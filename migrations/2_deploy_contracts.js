const FidelityToken = artifacts.require("./FidelityToken.sol");

const web3 = require("web3-utils");

module.exports = (deployer, network, [owner]) => {
  return deployer
    .then(() => deployer.deploy(FidelityToken))
    .then(() => FidelityToken.deployed())
};