import { ethers, upgrades } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying Eurium with account:", deployer.address);

    // Roles (for demo purposes, using deployer for all roles)
    const admin = deployer.address;
    const pauser = deployer.address;
    const minter = deployer.address;
    const upgrader = deployer.address;
    const auditor = deployer.address;

    const Eurium = await ethers.getContractFactory("Eurium");
    console.log("Deploying Eurium Proxy...");

    const eurium = await upgrades.deployProxy(Eurium, [admin, pauser, minter, upgrader, auditor], {
        initializer: "initialize",
        kind: "uups",
    });

    await eurium.waitForDeployment();
    const euriumAddress = await eurium.getAddress();
    console.log("Eurium deployed to:", euriumAddress);

    // Deploy ReserveManager
    const ReserveManager = await ethers.getContractFactory("ReserveManager");
    const reserveManager = await ReserveManager.deploy(euriumAddress, admin);
    await reserveManager.waitForDeployment();
    const reserveManagerAddress = await reserveManager.getAddress();
    console.log("ReserveManager deployed to:", reserveManagerAddress);

    // Deploy Treasury
    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy(admin);
    await treasury.waitForDeployment();
    const treasuryAddress = await treasury.getAddress();
    console.log("Treasury deployed to:", treasuryAddress);

    // Grant MINTER_ROLE to ReserveManager (Eurium)
    const MINTER_ROLE = await eurium.MINTER_ROLE();
    await (await eurium.grantRole(MINTER_ROLE, reserveManagerAddress)).wait();
    console.log("Granted MINTER_ROLE to ReserveManager on Eurium");

    // Grant MANAGER_ROLE to deployer (ReserveManager)
    const MANAGER_ROLE = await reserveManager.MANAGER_ROLE();
    await (await reserveManager.grantRole(MANAGER_ROLE, admin)).wait();
    console.log("Granted MANAGER_ROLE to admin on ReserveManager");

    // Grant WITHDRAWER_ROLE to deployer (Treasury)
    const WITHDRAWER_ROLE = await treasury.WITHDRAWER_ROLE();
    await (await treasury.grantRole(WITHDRAWER_ROLE, admin)).wait();
    console.log("Granted WITHDRAWER_ROLE to admin on Treasury");

    console.log("Deployment complete!");

    // Summary for manifest
    const manifest = {
        Eurium: euriumAddress,
        ReserveManager: reserveManagerAddress,
        Treasury: treasuryAddress,
        Roles: {
            Admin: admin,
            Pauser: pauser,
            Minter: minter,
            Upgrader: upgrader,
        }
    };

    console.log("Manifest:", JSON.stringify(manifest, null, 2));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
