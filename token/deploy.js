
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying with account:", deployer.address);
    
    const RogerToken = await hre.ethers.getContractFactory("RogerToken");
    const token = await RogerToken.deploy(
        "Roger",
        "ROGER", 
        1000000  // 1M initial supply
    );
    
    await token.deployed();
    console.log("RogerToken deployed to:", token.address);
    console.log("View on Basescan:", `https://basescan.org/address/${token.address}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
