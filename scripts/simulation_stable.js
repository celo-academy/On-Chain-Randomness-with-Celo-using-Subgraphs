const hre = require("hardhat");

async function setup(token) {
    console.log("Setting up accounts");
    const accountList = await hre.ethers.getSigners();

    for(let i = 1; i <= 9; i++) {
        console.log("Transfer token to account: ", accountList[i].address);
        const txToken = await token.connect(accountList[0]).transfer(accountList[i].address, hre.ethers.utils.parseEther("1"));
        await txToken.wait();
    }
    console.clear();
    return accountList;
}

async function simulation(accountList, token, factory) {
    console.log("Start simulation");

    let manager = accountList[1];
    let depositAmount = hre.ethers.utils.parseEther("1");

    console.log("Create new stable lottrey club");
    const txCreate = await factory.connect(manager).createStableClub("Clubs Stable eusro", depositAmount, 8, token.address);
    const receiptCreate = await txCreate.wait();
    const eventCreate = receiptCreate.events[0];
    const clubAddress = eventCreate.args[0];
    console.clear();

    console.log("Start lottrey and member register");
    const club = await hre.ethers.getContractAt("LottreyClubStable", clubAddress);

    const txStart = await club.connect(manager).startLottrey();
    await txStart.wait();

    for(let i = 2; i <= 9; i++) {
        console.log("Member register: ", accountList[i].address);
        const txApprove = await token.connect(accountList[i]).approve(club.address, depositAmount);
        await txApprove.wait();

        const txRegister = await club.connect(accountList[i]).registerMember(depositAmount);
        await txRegister.wait();
    }
    console.clear();

    console.log("End lottrey and draw")
    const txEnd = await club.connect(manager).endLottreyAndDraw();
    const receiptEnd = await txEnd.wait();
    const eventWiner = receiptEnd.events[1];
    const winer = eventWiner.args[0];
    console.clear();

    console.log("======================================")
    console.log("Factory Address:     ", factory.address);
    console.log("Manager Address:     ", manager.address);
    console.log("Club Address   :     ", club.address);
    console.log("Winer Address  :     ", winer);
    console.log("======================================")

}

async function main(){
    const token = await hre.ethers.getContractAt("Token","0xE4D517785D091D3c54818832dB6094bcc2744545");
    const factory = await hre.ethers.getContractAt("LottreyClubFactory","0x6E023854ceeeD3FC1934622c9c324Db7C8341ba7");
    const accountList = await setup(token);
    await simulation(accountList, token, factory);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 