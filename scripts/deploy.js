const hre = require("hardhat");

async function main(){
    console.log("Deploy Contract");

    const contract = await hre.ethers.getContractFactory("LotteryClubFactory");
    const factory = await contract.deploy();
    await factory.deployed();

    const contracts = await hre.ethers.getContractFactory("NFT");
    const nft = await contracts.deploy();
    await nft.deployed();
    console.clear();

    console.log("Factory Address : ", factory.address);
    console.log("NFT Address     : ", nft.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})