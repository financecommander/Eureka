const express = require('express');
const ethers = require('ethers');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// TODO: Load contract ABIs and addresses from config

app.post('/verify', async (req, res) => {
    const { settlementId, attorneyAddress } = req.body;
    try {
        // TODO: Connect to Ethereum provider
        // TODO: Call AttorneyVerificationNode.verifySignature
        res.json({ status: 'verified', settlementId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/settlement/:id', async (req, res) => {
    const { id } = req.params;
    try {
        // TODO: Connect to Ethereum provider
        // TODO: Query SettlementVerificationRegistry.settlements
        res.json({ id, status: 'REGISTERED' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/anchor', async (req, res) => {
    const { settlementId, asset, amount } = req.body;
    try {
        // TODO: Connect to Ethereum provider
        // TODO: Call SettlementAnchor.lockAsset and anchorSettlement
        res.json({ status: 'anchored', settlementId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(port, () => {
    console.log(`API server running on port ${port}`);
});
