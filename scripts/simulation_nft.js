const hre = require("hardhat");

async function setup(){
    console.log("Setting up account");
    const accountList = await hre.ethers.getSigners();
    for(let i = 1; i <= 9; i++) {
        console.log("Transfer to : ", accountList[i].address);
        let tx = {
            to: accountList[i].address,
            value: hre.ethers.utils.parseEther("2")
        }
        let txTransfer = await accountList[0].sendTransaction(tx);
        await txTransfer.wait();
    }
    console.clear();
    return accountList
}

async function simulation(accountList, factory, faucet) {
    const manager = accountList[1];
    const deposit = hre.ethers.utils.parseEther("1");

    console.log("Create new NFT club");
    const txFaucet = await faucet.connect(manager).faucet();
    await txFaucet.wait();
    const tokenId = await faucet.getId();

    const txCreate = await factory.connect(manager).createClubNFT(
        "Coba duluserssddss",
        deposit,
        8
    );
    const receiptCreate = await txCreate.wait();
    const eventCreate = receiptCreate.events[0];
    const club = await hre.ethers.getContractAt("LotteryClubNFT", eventCreate.args[0]);
    console.clear();

    console.log("Start lottery");
    const txApprove = await faucet.connect(manager).approve(
        club.address,
        tokenId.sub(1)
    );
    await txApprove.wait();

    const txStart = await club.connect(manager).start(
        faucet.address,
        tokenId.sub(1)
    );
    await txStart.wait();
    console.clear();

    console.log("Register member");
    for(let i = 2; i <= 9; i++) {
        console.log("Member register : ", accountList[i].address);
        let txRegister = await club.connect(accountList[i]).registerMember({value:deposit});
        await txRegister.wait(2);
    }
    console.clear();

    console.log("Finish and draw");
    const txFinish = await club.connect(manager).finishAndDraw();
    const receiptFinish = await txFinish.wait();
    const eventFinish = receiptFinish.events[1];
    const winer = eventFinish.args[1]
    console.clear();
    console.log("======================================")
    console.log("Factory Address:     ", factory.address);
    console.log("Manager Address:     ", manager.address);
    console.log("Club Address   :     ", club.address);
    console.log("Winer Address  :     ", winer);
    console.log("======================================");
}

async function main(){
    factoryAddress = "0x86e688700cA81Eb369b636393667618cF3f053B2";
    faucetAddress = "0x182Be05B2c3A4DCA71547893b968f834860F819A";

    const factory = await hre.ethers.getContractAt("LotteryClubFactory", factoryAddress);
    const faucet = await hre.ethers.getContractAt("NFT", faucetAddress);

    accountList = await setup();
    await simulation(accountList, factory, faucet);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})