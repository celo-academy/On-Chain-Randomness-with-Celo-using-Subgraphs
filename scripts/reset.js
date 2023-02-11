const hre = require("hardhat");


async function main() {
    let accountList = await hre.ethers.getSigners();
    for(let i = 1; i <= 10; i++){
        let balance = await hre.ethers.provider.getBalance(accountList[i].address);
        let transferAmount = balance.sub(hre.ethers.utils.parseEther("0.1"));

        let tx = {
            to: accountList[0].address,
            value: transferAmount
        }
        await accountList[i].sendTransaction(tx).then((txObject) => {
            console.log("======================================")
            console.log("Account         :          ", accountList[i].address);
            console.log("Amount          :", hre.ethers.utils.formatEther(transferAmount));
            console.log("Transaction Hash: ", txObject.hash);
            console.log("======================================")
        })
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})