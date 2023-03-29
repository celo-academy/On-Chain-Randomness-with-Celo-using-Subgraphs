const hre = require("hardhat");

async function main(){
    console.log("Deploy Contract");

    const contract = await hre.ethers.getContractFactory("LotteryClubFactory");
    const factory = await contract.deploy();
    await factory.deployed();

    console.log("Factory Address : ", factory.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})