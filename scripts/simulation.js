const hre = require("hardhat");

async function setup(token) {
    console.log("Setting up accounts");
    const accountList = await hre.ethers.getSigners();
    const transferAmount = await hre.ethers.utils.parseEther("1.5");

    for(let i = 1; i <= 9; i++) {
        console.log("Transfer to: ", accountList[i].address);
        const tx = await token.connect(accountList[0]).transfer(
            accountList[i].address,
            transferAmount
        );
        await tx.wait();
    }
    console.clear();
    return accountList;
}

async function simulation(accountList, factory, token) {
    console.log("Simulation");
    console.clear();

    let manager = accountList[1];
    let depositAmount = hre.ethers.utils.parseEther("0.5");

    console.log("Create new lottrey club");
    const txCreate = await factory.connect(manager).createClub(
        "Sut",
        depositAmount,
        8,
        token.address
    );
    const receiptCreate = await txCreate.wait();
    const event = receiptCreate.events[0];
    const clubAddress = event.args[0];
    console.clear();

    console.log("Start lottery and member register");
    const club = await hre.ethers.getContractAt("LotteryClub", clubAddress);

    const txStart = await club.connect(manager).start();
    await txStart.wait();
    // console.log("club: ", club.address)

    for(let i = 2; i <= 9; i++) {
        console.log("Member register: ", accountList[i].address);
        const txApprove = await token.connect(accountList[i]).approve(club.address, depositAmount);
        await txApprove.wait();

        const txRegister = await club.connect(accountList[i]).register();
        await txRegister.wait();
    }
    console.clear();

    console.log("Finish and draw");
    const txFinish = await club.connect(manager).finishAndDraw();
    const receiptFinish = await txFinish.wait();
    const eventWiner = receiptFinish.events[1];
    const winer = eventWiner.args[1];
    console.clear();

    console.log("======================================")
    console.log("Factory Address:     ", factory.address);
    console.log("Manager Address:     ", manager.address);
    console.log("Club Address   :     ", club.address);
    console.log("Winer Address  :     ", winer);
    console.log("======================================");

}

async function main() {
    const token = await hre.ethers.getContractAt("Token", "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9");
    const factory = await hre.ethers.getContractAt("LotteryClubFactory", "0x86e688700cA81Eb369b636393667618cF3f053B2");
    const accountList = await setup(token);
    await simulation(accountList, factory, token);
}

main().catch((error) => {
    console.error(error);
    process.exitCode=1;
})