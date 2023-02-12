const hre = require("hardhat");

async function setup(nft) {
    console.log("Setting up accounts");
    const accountList = await hre.ethers.getSigners();
    for (let i = 1; i <= 9; i++) {
        let tx = {
            to: accountList[i].address,
            value: hre.ethers.utils.parseEther("1.5"),
        };
        await accountList[0].sendTransaction(tx).then((txObject) => {
            console.log("======================================");
            console.log("Account:          ", accountList[i].address);
            console.log("Transaction Hash: ", txObject.hash);
            console.log("======================================");
        });
    }
    console.clear();

    console.log("Request sample NFT");
    const txRequest = await nft.connect(accountList[1]).getSampleNFT();
    await txRequest.wait();
    console.clear();

    return accountList;
}

async function simulation(accountList, nft, factory) {
    console.log("Simulation");
    console.clear();

    let manager = accountList[1];
    let ticketPrice = hre.ethers.utils.parseEther("0.5");

    console.log("Create new lottrey club");
    const txCreate = await factory
        .connect(manager)
        .createNftClub("Club NFTS", ticketPrice, 8);
    const receiptCreate = await txCreate.wait();
    const event = receiptCreate.events[0];
    const clubAddress = event.args[0];
    console.clear();

    console.log("Start lottrey and member register");
    const club = await hre.ethers.getContractAt("LottreyClubNFT", clubAddress);

    const txApprove = await nft.connect(manager).approve(club.address, 0);
    await txApprove.wait();

    const txStart = await club
        .connect(manager)
        .startLottreyAndSetPrize(nft.address, 0);
    await txStart.wait();
    console.clear();

    for (let i = 2; i <= 9; i++) {
        console.log("Member Register: ", accountList[i].address);
        const txRegister = await club
            .connect(accountList[i])
            .registerMember({ value: ticketPrice });
        await txRegister.wait();
    }
    console.clear();

    console.log("End lottrey and draw");
    const txEnd = await club.connect(manager).endLottreyAndDraw();
    const receiptEnd = await txEnd.wait();
    const eventWiner = receiptEnd.events[1];
    const winer = eventWiner.args[0];
    console.clear();

    console.log("======================================");
    console.log("Factory Address:     ", factory.address);
    console.log("Manager Address:     ", manager.address);
    console.log("Club Address   :     ", club.address);
    console.log("Winer Address  :     ", winer);
    console.log("======================================");
}

async function main() {
    const nft = await hre.ethers.getContractAt("MyNFT", "0xe269dF872C98dff17651374Ba941053b0694A2A8");
    const factory = await hre.ethers.getContractAt("LottreyClubFactory", "0x4F57Dee9e616a36d1840A59A6d51840c0ac34292");
    const accountList = await setup(nft);
    await simulation(accountList, nft, factory);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
