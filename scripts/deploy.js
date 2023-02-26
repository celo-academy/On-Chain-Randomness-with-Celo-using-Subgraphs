const hre = require("hardhat");


async function main() {
    console.log("Deploy factory & faucet");
    const factoryContract = await hre.ethers.getContractFactory("LotteryClubFactory");
    const faucetContract = await hre.ethers.getContractFactory("NFT");

    const factory = await factoryContract.deploy();
    await factory.deployed();

    const faucet = await faucetContract.deploy();
    await faucet.deployed();
    console.clear();

    console.log("Factory : ", factory.address);
    console.log("Faucet : ", faucet.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})