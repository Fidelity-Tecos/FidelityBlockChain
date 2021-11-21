// scripts/upgrade_box.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const FidelityImplementationContract2 = await ethers.getContractFactory('FidelityImplementationContract2');
  console.log('Upgrading FidelityImplementationContract...');
  await upgrades.upgradeProxy('0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0', FidelityImplementationContract2);
  console.log('FidelityImplementationContract upgraded');
}

main();