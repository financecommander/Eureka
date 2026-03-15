const { ethers } = require('hardhat');

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);

  const SettlementVerifier = await ethers.getContractFactory('SettlementVerifier');
  const contract = await SettlementVerifier.deploy();
  await contract.waitForDeployment();

  console.log('SettlementVerifier deployed to:', contract.target);
  return contract.target;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
