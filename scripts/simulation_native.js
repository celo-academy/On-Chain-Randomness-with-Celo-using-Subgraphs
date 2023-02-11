const hre = require("hardhat");

async function setup() {
    console.log("Setting up accounts");
    const accountList = await hre.ethers.getSigners();

    for(let i = 1; i <= 9; i++){
        let tx = {
            to: accountList[i].address,
            value: hre.ethers.utils.parseEther("0.7")
        }
        await accountList[0].sendTransaction(tx).then(
            (txObject) => {
                console.log("======================================")
                console.log("Account:          ", accountList[i].address);
                console.log("Transaction Hash: ", txObject.hash);
                console.log("======================================")
            }
        )
    }
    console.clear();
    return accountList;
}

async function simulation(accountList, factory) {
    console.log("Simulation");
    console.clear()

    let manager = accountList[1];
    let depositAmount = hre.ethers.utils.parseEther("0.5");

    console.log("Create new lottrey club")
    const txCreate = await factory.connect(manager).createNativeClub("Club Native", depositAmount, 8);
    const receiptCreate = await txCreate.wait();
    const event = receiptCreate.events[0];
    const clubAddress = event.args[0];
    console.clear();

    console.log("Start Lottrey and Member Register");
    const club = await hre.ethers.getContractAt("LottreyClubNative", clubAddress);
    const txStart = await club.connect(manager).startLottrey();
    await txStart.wait();
    console.clear();

    for(let i = 2; i <= 9; i++){
        console.log("Member Register: ", accountList[i].address);
        const txRegister = await club.connect(accountList[i]).registerMember({value: depositAmount});
        await txRegister.wait();
    }
    console.clear();

    console.log("End lottrey and draw")
    const txEnd = await club.connect(manager).endLottreyAndDraw();
    const receiptEnd = await txEnd.wait();
    const eventWiner = receiptEnd.events[0];
    const winer = eventWiner.args[0];
    console.clear();

    console.log("======================================")
    console.log("Factory Address:     ", factory.address);
    console.log("Manager Address:     ", manager.address);
    console.log("Club Address   :     ", club.address);
    console.log("Winer Address  :     ", winer);
    console.log("======================================")

}

async function main() {
    const accountList = await setup();
    const factory = await hre.ethers.getContractAt("LottreyClubFactory", "0x6E023854ceeeD3FC1934622c9c324Db7C8341ba7");
    await simulation(accountList, factory);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})