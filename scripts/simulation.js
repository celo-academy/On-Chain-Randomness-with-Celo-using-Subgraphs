const hre = require("hardhat");

async function setup(token) {
    console.log("Setting up...");
    const accounts = await hre.ethers.getSigners();
    const amount = hre.ethers.utils.parseEther("2")
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
    const deposit = hre.ethers.utils.parseEther("1");
    const manager = accountList[1];
    
    console.clear();
    console.log("Create new club");
    const txCreate = await factory.connect(manager).createClubToken(
        "Club 1",
        deposit,
        8,
        token.address
    );
    const receiptCreate = await txCreate.wait();
    const clubAddress = receiptCreate.events[0].args[0];
    const club = await hre.ethers.getContractAt("LotteryClubToken", clubAddress)
    console.clear();
    // console.log(clubAddress)
    
    console.log("Start lottery and register");
    const txStart = await club.connect(manager).start();
    await txStart.wait();

    for(let i = 2; i <= 9; i++) {
        console.log("Member register: ", accountList[i].address);
        const txApprove = await token.connect(accountList[i]).approve(club.address, deposit);
        await txApprove.wait();

        const txRegister = await club.connect(accountList[i]).register();
        await txRegister.wait();
    }
    console.clear();

    console.log("Draw lottery");
    const txDraw = await club.connect(manager).draw();
    const receiptDraw = await txDraw.wait();
    const winner = receiptDraw.events[1].args[0];
    console.clear();

    console.log("Manager claim fee");
    const txClaimFee = await club.connect(manager).claimFee();
    await txClaimFee.wait();

    console.log("======================================");
    console.log("Factory Address:     ", factory.address);
    console.log("Manager Address:     ", manager.address);
    console.log("Club Address   :     ", club.address);
    console.log("Winer Address  :     ", winner);
    console.log("======================================");
}

async function main() {
    const token = await hre.ethers.getContractAt("Token", "0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9");
    const factory = await hre.ethers.getContractAt("LotteryClubFactory","0xFA30dc124207E1e7B9499707BC5cA6B5654bbAb3");
    const accountList = await setup(token);
    await simulation(accountList, token, factory);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})