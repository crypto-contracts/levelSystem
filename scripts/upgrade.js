const {ethers, upgrades} = require("hardhat");

async function main() {
    const pre_leve = "0xF77D58aAB7e0660E0cb845320167155b9E22F17c";

    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Level = await ethers.getContractFactory("Level");
    const level = await upgrades.upgradeProxy(pre_leve, Level);

    console.log("Level upgraded");
}

main();
