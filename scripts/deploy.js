const {ethers, upgrades} = require("hardhat");

async function main() {
    const _safe = "0x874e52963718737db2A5C77255cDA9e6818c01a8";
    const _copper = "0x53d55024E171d4e80a319e237DBfd26041B86873";
    const _mst = "0x152888854378201e173490956085c711f1DeD565";

    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Level = await ethers.getContractFactory("Level");
    const level = await upgrades.deployProxy(Level, [_safe, _copper, _mst]);

    await level.deployed();

    console.log("Level address:", level.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
