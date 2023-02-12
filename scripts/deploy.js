const hre = require("hardhat");

async function main() {
    console.log("Deploy Factory Contract");
    const factory = await hre.ethers.getContractFactory("LottreyClubFactory");
    const factoryContract = await factory.deploy();
    await factoryContract.deployed();
    console.clear();

    console.log("Deploy MyNFT Contract");
    const myNFT = await hre.ethers.getContractFactory("MyNFT");
    const myNFTContract = await myNFT.deploy();
    await myNFTContract.deployed();
    console.clear();

    console.log("Factory Contract Address: ", factoryContract.address);
    console.log("MyNFT Contract Address: ", myNFTContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})