const express = require('express');
const ethers = require('ethers');
require('dotenv').config();

const app = express();
app.use(express.json());

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

app.post('/verify', async (req, res) => {
    const { settlementId, verified } = req.body;
    // TODO: Connect to SettlementVerificationRegistry contract
    res.status(200).json({ message: 'Verification submitted', settlementId });
});

app.get('/settlement/:id', async (req, res) => {
    const { id } = req.params;
    // TODO: Fetch settlement data from contract
    res.status(200).json({ id, status: 'pending' });
});

app.post('/anchor', async (req, res) => {
    const { settlementId, assetContract, amount } = req.body;
    // TODO: Call SettlementAnchor.lockAsset
    res.status(200).json({ message: 'Asset anchored', settlementId });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));
