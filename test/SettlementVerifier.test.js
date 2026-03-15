const { expect } = require('chai');
const { ethers } = require('hardhat');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

describe('SettlementVerifier', function () {
  let contract, owner, addr1, addr2;
  let merkleTree, merkleRoot;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const SettlementVerifier = await ethers.getContractFactory('SettlementVerifier');
    contract = await SettlementVerifier.deploy();
    await contract.waitForDeployment();

    // Setup Merkle Tree for testing
    const leaves = [
      keccak256(ethers.solidityPacked(['address', 'uint256'], [addr1.address, ethers.parseEther('1')])),
      keccak256(ethers.solidityPacked(['address', 'uint256'], [addr2.address, ethers.parseEther('2')]))
    ];
    merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    merkleRoot = merkleTree.getRoot();
    await contract.updateMerkleRoot(ethers.hexlify(merkleRoot));

    // Fund the contract
    await owner.sendTransaction({ to: contract.target, value: ethers.parseEther('10') });
  });

  it('should allow valid claims with correct Merkle proof', async function () {
    const amount = ethers.parseEther('1');
    const leaf = keccak256(ethers.solidityPacked(['address', 'uint256'], [addr1.address, amount]));
    const proof = merkleTree.getHexProof(leaf);
    const initialBalance = await ethers.provider.getBalance(addr1.address);

    await expect(contract.connect(addr1).claimSettlement(amount, proof))
      .to.emit(contract, 'SettlementClaimed')
      .withArgs(addr1.address, amount);

    const finalBalance = await ethers.provider.getBalance(addr1.address);
    expect(finalBalance - initialBalance).to.be.closeTo(amount, ethers.parseEther('0.01'));
  });

  it('should reject invalid Merkle proof', async function () {
    const amount = ethers.parseEther('1');
    await expect(contract.connect(addr1).claimSettlement(amount, []))
      .to.be.revertedWith('Invalid proof');
  });

  it('should reject double claims', async function () {
    const amount = ethers.parseEther('1');
    const leaf = keccak256(ethers.solidityPacked(['address', 'uint256'], [addr1.address, amount]));
    const proof = merkleTree.getHexProof(leaf);

    await contract.connect(addr1).claimSettlement(amount, proof);
    await expect(contract.connect(addr1).claimSettlement(amount, proof))
      .to.be.revertedWith('Already claimed');
  });
});
