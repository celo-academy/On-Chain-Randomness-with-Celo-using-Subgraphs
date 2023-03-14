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

async function simulation(accountList, nft, factory) {
    console.log("Start simulation");
    const manager = accountList[1];
    const deposit = hre.ethers.utils.parseEther("1");
    console.clear();

    console.log("Create new club");
    const txFaucet = await nft.connect(manager).faucet();
    await txFaucet.wait();
    const tokenId = await nft.getId();

    const txCreate = await factory.connect(manager).clubNFT(
        "Finals Test NFT",
        deposit,
        8
    );
    const receiptCreate = await txCreate.wait();
    const clubAddress = receiptCreate.events[0].args[0];
    const club = await hre.ethers.getContractAt("LotteryClubNFT", clubAddress);
    console.clear();
    
    console.log("Start lottery and register members");
    const txApprove = await nft.connect(manager).approve(club.address, tokenId.sub(1));
    await txApprove.wait();

    const txStart = await club.connect(manager).start(nft.address, tokenId.sub(1));
    await txStart.wait();

    for(let i = 2; i <= 9; i++) {
        console.log("Member register: ", accountList[i].address);
        const txRegister = await club.connect(accountList[i]).register({value:deposit});
        await txRegister.wait();
    }
    console.clear();

    console.log("Draw lottery")
    const txDraw = await club.connect(manager).draw();
    const receiptDraw = await txDraw.wait();
    const winner = receiptDraw.events[1].args[1];
    console.clear();

    console.log("Manager claim fee");;
    const txClaimFee = await club.connect(manager).claimFee();
    await txClaimFee.wait();
    console.clear();

    console.log("Update member limit & deposit");
    const txMembersLimit = await club.connect(manager).setMembersLimit(6);
    await txMembersLimit.wait();

    const txDeposit = await club.connect(manager).setDeposit(hre.ethers.utils.parseEther("0.5"));
    await txDeposit.wait();
    console.clear();

    console.log("======================================");
    console.log("Factory Address:     ", factory.address);
    console.log("Manager Address:     ", manager.address);
    console.log("Club Address   :     ", club.address);
    console.log("Winer Address  :     ", winner);
    console.log("======================================");
}

async function main(){
    nft = await hre.ethers.getContractAt("NFT", "0x5EF7dF43D5162c73008b5e65050B7899A64C77c3");
    factory = await hre.ethers.getContractAt("LotteryClubFactory", "0x7d92b85cbEE92E3aA83586151Aeec8Fb75192247");
    const accountList = await setup();
    await simulation(accountList, nft, factory);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})