const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('SettlementVerificationRegistry', function () {
  let registry, anchor;
  let owner, attorney;

  beforeEach(async function () {
    [owner, attorney] = await ethers.getSigners();
    const SettlementAnchor = await ethers.getContractFactory('SettlementAnchor');
    anchor = await SettlementAnchor.deploy();
    await anchor.deployed();

    const SettlementVerificationRegistry = await ethers.getContractFactory('SettlementVerificationRegistry');
    registry = await SettlementVerificationRegistry.deploy();
    await registry.deployed();
  });

  it('should register a settlement', async function () {
    const settlementId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('test-settlement'));
    await expect(registry.registerSettlement(settlementId, anchor.address))
      .to.emit(registry, 'SettlementRegistered')
      .withArgs(settlementId, anchor.address);
  });

  // TODO: Add more tests for verification lifecycle
});
