const { ethers, upgrades } = require('hardhat');

async function main () {
  const FidelityImplementationContract = await ethers.getContractFactory('FidelityImplementationContract');
  console.log('Deploying FidelityImplementationContract...');
  const fidelityImplementationContract = await upgrades.deployProxy(FidelityImplementationContract, [100000], { initializer: 'init' });
  await fidelityImplementationContract.deployed();
  console.log('FidelityImplementationContract deployed to:', fidelityImplementationContract.address);
}

main();