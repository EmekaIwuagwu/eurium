const { ethers } = require("ethers");

async function checkBalance() {
    const provider = new ethers.JsonRpcProvider("https://rpc-amoy.polygon.technology");
    const address = "0x28e514Ce1a0554B83f6d5EEEE11B07D0e294D9F9";

    const balance = await provider.getBalance(address);
    const balanceInPOL = ethers.formatEther(balance);

    console.log(`Address: ${address}`);
    console.log(`Balance: ${balanceInPOL} POL`);
    console.log(`Balance (Wei): ${balance.toString()}`);
}

checkBalance().catch(console.error);
