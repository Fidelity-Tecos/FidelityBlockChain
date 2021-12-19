// scripts/upgrade_box.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const FidelityImplementationContract2 = await ethers.getContractFactory('FidelityImplementationContract2');
  console.log('Upgrading FidelityImplementationContract...');
  await upgrades.upgradeProxy('0x00Ab64886FD838Ca74e20406A44E53bE8B75264d', FidelityImplementationContract2);
  console.log('FidelityImplementationContract upgraded');
}

main();