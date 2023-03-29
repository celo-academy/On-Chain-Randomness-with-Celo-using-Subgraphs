const hre = require("hardhat");

async function setup(token) {
    console.log("Setting up...");
    const accounts = await hre.ethers.getSigners();
    const amount = hre.ethers.utils.parseEther("0.5")
    console.clear();

    for(let i = 1; i <= 9; i++) {
        console.log("Transfer to: ", accounts[i].address);
        const tx = await token.connect(accounts[0]).transfer(
            accounts[i].address,
            amount
        );
        await tx.wait();
    }

    return accounts;
}

async function simulation(accountList, token, factory) {
    console.log("Start simulation")
    manager = accountList[1]
    deposit = hre.ethers.utils.parseEther("0.01")
    console.clear();

    console.log("Create new club")
    const txCreate = await factory.connect(manager).clubToken(
        "Final Test Token",
        deposit,
        8,
        token.address
    );
    const receiptCreate = await txCreate.wait();
    const clubAddress = receiptCreate.events[0].args[0];
    const club = await hre.ethers.getContractAt("LotteryClubToken", clubAddress)
    console.clear();

    console.log("Start and register members")
    const txStart = await club.connect(manager).start();
    await txStart.wait();

    for(let i = 2; i <= 9; i++) {
        console.log("Member register: ", accountList[i].address);
        const txApprove = await token.connect(accountList[i]).approve(club.address, deposit);
        await txApprove.wait();

        const txRegister = await club.connect(accountList[i]).register();
        await txRegister.wait();
    }
    console.clear()

    console.log("Draw lottery")
    const txDraw = await club.connect(manager).draw();
    const receiptDraw = await txDraw.wait();
    const winner = receiptDraw.events[1].args[0];
    console.clear();
    
    console.log("Manager claim fee")
    const txClaimFee = await club.connect(manager).claimFee();
    await txClaimFee.wait();
    console.clear()

    console.log("Manager update members limit & deposit")
    const txSetDeposit = await club.connect(manager).setDeposit(hre.ethers.utils.parseEther("0.1"));
    await txSetDeposit.wait();

    const txSetLimit = await club.connect(manager).setMembersLimit(5);
    await txSetLimit.wait();
    console.clear()

    console.log("======================================");
    console.log("Factory Address:     ", factory.address);
    console.log("Manager Address:     ", manager.address);
    console.log("Club Address   :     ", club.address);
    console.log("Winer Address  :     ", winner);
    console.log("======================================");
}

async function main() {
    const token = await hre.ethers.getContractAt("Token", "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9");
    const factory = await hre.ethers.getContractAt("LotteryClubFactory","0x4643732F145813Ac030B1fE37e39b7d743173cAf");
    const accountList = await setup(token);
    await simulation(accountList, token, factory);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})