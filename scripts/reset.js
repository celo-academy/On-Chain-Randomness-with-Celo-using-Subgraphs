const hre = require("hardhat");

async function main() {
    let accountList = await hre.ethers.getSigners();
    for(let i = 1; i <= 9; i++) {
        let balance = await hre.ethers.provider.getBalance(accountList[i].address);
        if(balance.gte(hre.ethers.utils.parseEther("0.5"))) {
            console.log("Transfer from : ", accountList[i].address)
            let transferAmount = balance.sub(hre.ethers.utils.parseEther("0.1"));
            let tx = {
                to: accountList[0].address,
                value: transferAmount
            }
            await accountList[i].sendTransaction(tx);
        }
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})