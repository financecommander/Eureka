# Eureka Settlement Verifier

A smart contract-based settlement verification system using Merkle proofs for secure and efficient claim processing.

## Overview
This project implements a settlement verification chain for financial transactions, ensuring trustless and transparent processing of claims.

## Installation
1. Clone the repository: `git clone <repo-url>`
2. Install dependencies: `npm install`

## Compilation
Compile the smart contracts using Hardhat:
```bash
npm run compile
```

## Testing
Run the test suite to verify contract functionality:
```bash
npm test
```

## Deployment
Deploy the contracts to a testnet (e.g., Sepolia):
```bash
npm run deploy:testnet
```
Make sure to configure your Hardhat network settings in `hardhat.config.js` with your testnet provider and private key.

## Usage
- Update the Merkle root with settlement data using `updateMerkleRoot()`.
- Users can claim their settlements by providing a valid Merkle proof via `claimSettlement()`.

## Integration
Use the ethers.js library to interact with the deployed contract from your JavaScript/TypeScript application. Example:
```javascript
const ethers = require('ethers');
const contract = new ethers.Contract(contractAddress, abi, provider);
```
