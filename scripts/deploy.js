const hre = require("hardhat");

async function main() {
    console.log("Deploy Factory Contract");
    const factory = await hre.ethers.getContractFactory("LottreyClubFactory");
    const factoryContract = await factory.deploy();
    await factoryContract.deployed();
    console.log("Factory Contract Address: ", factoryContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})