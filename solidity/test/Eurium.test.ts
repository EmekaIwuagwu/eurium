import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { Eurium, ReserveManager, Treasury } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Eurium Stablecoin", function () {
    let eurium: Eurium;
    let reserveManager: ReserveManager;
    let treasury: Treasury;
    let owner: SignerWithAddress;
    let pauser: SignerWithAddress;
    let minter: SignerWithAddress;
    let auditor: SignerWithAddress;
    let user: SignerWithAddress;

    beforeEach(async function () {
        [owner, pauser, minter, auditor, user] = await ethers.getSigners();

        const EuriumFactory = await ethers.getContractFactory("Eurium");
        eurium = (await upgrades.deployProxy(
            EuriumFactory,
            [owner.address, pauser.address, minter.address, owner.address, auditor.address],
            { kind: "uups" }
        )) as unknown as Eurium;

        const ReserveManagerFactory = await ethers.getContractFactory("ReserveManager");
        reserveManager = await ReserveManagerFactory.deploy(await eurium.getAddress(), owner.address);

        const TreasuryFactory = await ethers.getContractFactory("Treasury");
        treasury = await TreasuryFactory.deploy(owner.address);
    });

    describe("Deployment", function () {
        it("Should set the right name and symbol", async function () {
            expect(await eurium.name()).to.equal("Eurium");
            expect(await eurium.symbol()).to.equal("EUI");
        });

        it("Should grant roles correctly", async function () {
            expect(await eurium.hasRole(await eurium.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
            expect(await eurium.hasRole(await eurium.PAUSER_ROLE(), pauser.address)).to.be.true;
            expect(await eurium.hasRole(await eurium.MINTER_ROLE(), minter.address)).to.be.true;
        });
    });

    describe("Minting & Burning", function () {
        it("Should allow minter to mint", async function () {
            const amount = ethers.parseEther("1000");
            await eurium.connect(minter).mint(user.address, amount);
            expect(await eurium.balanceOf(user.address)).to.equal(amount);
        });

        it("Should fail if non-minter tries to mint", async function () {
            await expect(
                eurium.connect(user).mint(user.address, 100)
            ).to.be.reverted;
        });
    });

    describe("Pausable", function () {
        it("Should prevent transfers when paused", async function () {
            await eurium.connect(minter).mint(owner.address, 1000);
            await eurium.connect(pauser).pause();
            await expect(
                eurium.transfer(user.address, 100)
            ).to.be.reverted;
        });

        it("Should allow transfers when unpaused", async function () {
            await eurium.connect(minter).mint(owner.address, 1000);
            await eurium.connect(pauser).pause();
            await eurium.connect(pauser).unpause();
            await eurium.transfer(user.address, 100);
            expect(await eurium.balanceOf(user.address)).to.equal(100);
        });
    });

    describe("Redemption Flow", function () {
        it("Should handle redemption requests", async function () {
            const amount = ethers.parseEther("500");
            await eurium.connect(minter).mint(user.address, amount);

            await eurium.connect(user).redeemRequest(amount, "RED-001");

            expect(await eurium.balanceOf(user.address)).to.equal(0);
            expect(await eurium.balanceOf(await eurium.getAddress())).to.equal(amount);
        });

        it("Should allow admin to finalize redemptions (burning tokens)", async function () {
            const amount = ethers.parseEther("500");
            await eurium.connect(minter).mint(user.address, amount);

            const tx = await eurium.connect(user).redeemRequest(amount, "RED-001");
            const receipt = await tx.wait();
            const event = receipt?.logs.find(log => (log as any).fragment?.name === "RedemptionRequested");
            const internalId = (event as any).args.internalId;

            const totalSupplyBefore = await eurium.totalSupply();
            await eurium.connect(owner).finalizeRedemption(internalId);
            const totalSupplyAfter = await eurium.totalSupply();

            expect(totalSupplyBefore - totalSupplyAfter).to.equal(amount);
            expect(await eurium.balanceOf(await eurium.getAddress())).to.equal(0);
        });
    });
});
