import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { Eurium, ReserveManager, Treasury } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Eurium Stablecoin - Comprehensive Test Suite", function () {
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

    describe("Deployment & Initialization", function () {
        it("Should set the correct name and symbol", async function () {
            expect(await eurium.name()).to.equal("Eurium");
            expect(await eurium.symbol()).to.equal("EUI");
        });

        it("Should set correct decimals", async function () {
            expect(await eurium.decimals()).to.equal(18);
        });

        it("Should grant roles correctly", async function () {
            expect(await eurium.hasRole(await eurium.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
            expect(await eurium.hasRole(await eurium.PAUSER_ROLE(), pauser.address)).to.be.true;
            expect(await eurium.hasRole(await eurium.MINTER_ROLE(), minter.address)).to.be.true;
            expect(await eurium.hasRole(await eurium.AUDITOR_ROLE(), auditor.address)).to.be.true;
        });

        it("Should reject zero addresses in initialization", async function () {
            const EuriumFactory = await ethers.getContractFactory("Eurium");
            await expect(
                upgrades.deployProxy(
                    EuriumFactory,
                    [ethers.ZeroAddress, pauser.address, minter.address, owner.address, auditor.address],
                    { kind: "uups" }
                )
            ).to.be.reverted;
        });
    });

    describe("Minting & Burning", function () {
        it("Should allow minter to mint tokens", async function () {
            const amount = ethers.parseEther("1000");
            await eurium.connect(minter).mint(user.address, amount);
            expect(await eurium.balanceOf(user.address)).to.equal(amount);
        });

        it("Should fail minting to zero address", async function () {
            await expect(
                eurium.connect(minter).mint(ethers.ZeroAddress, 100)
            ).to.be.revertedWith("Cannot mint to zero address");
        });

        it("Should enforce max supply cap", async function () {
            const maxSupply = await eurium.MAX_SUPPLY();
            await expect(
                eurium.connect(minter).mint(user.address, maxSupply + 1n)
            ).to.be.revertedWith("Exceeds maximum supply");
        });

        it("Should fail if non-minter tries to mint", async function () {
            await expect(
                eurium.connect(user).mint(user.address, 100)
            ).to.be.reverted;
        });
    });

    describe("Pausable Functionality", function () {
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

        it("Should allow users to cancel redemption", async function () {
            const amount = ethers.parseEther("500");
            await eurium.connect(minter).mint(user.address, amount);

            const tx = await eurium.connect(user).redeemRequest(amount, "RED-001");
            const receipt = await tx.wait();
            const event = receipt?.logs.find(log => (log as any).fragment?.name === "RedemptionRequested");
            const internalId = (event as any).args.internalId;

            await eurium.connect(user).cancelRedemption(internalId);
            expect(await eurium.balanceOf(user.address)).to.equal(amount);
        });

        it("Should allow admin to finalize redemptions", async function () {
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
        });

        it("Should reject empty redemption ID", async function () {
            const amount = ethers.parseEther("500");
            await eurium.connect(minter).mint(user.address, amount);

            await expect(
                eurium.connect(user).redeemRequest(amount, "")
            ).to.be.revertedWith("Redemption ID cannot be empty");
        });
    });

    describe("Reserve Proof Management", function () {
        it("Should allow auditor to update reserve proof", async function () {
            const mockRoot = ethers.keccak256(ethers.toUtf8Bytes("mock-root"));
            await eurium.connect(auditor).updateReserveProof(mockRoot);

            expect(await eurium.currentReserveRoot()).to.equal(mockRoot);
            expect(await eurium.lastReserveUpdate()).to.be.greaterThan(0);
        });

        it("Should reject zero hash for reserve proof", async function () {
            await expect(
                eurium.connect(auditor).updateReserveProof(ethers.ZeroHash)
            ).to.be.revertedWith("Reserve root cannot be zero");
        });
    });

    describe("Snapshot Functionality", function () {
        it("Should create snapshots", async function () {
            await eurium.connect(minter).mint(user.address, 1000);
            await eurium.connect(owner).snapshot();
            const snapshotId = await eurium.getCurrentSnapshotId();
            expect(snapshotId).to.be.greaterThan(0);
        });
    });

    describe("ReserveManager", function () {
        beforeEach(async function () {
            // Grant MINTER_ROLE to ReserveManager
            const MINTER_ROLE = await eurium.MINTER_ROLE();
            await eurium.connect(owner).grantRole(MINTER_ROLE, await reserveManager.getAddress());

            // Grant MANAGER_ROLE to owner
            const MANAGER_ROLE = await reserveManager.MANAGER_ROLE();
            await reserveManager.connect(owner).grantRole(MANAGER_ROLE, owner.address);
        });

        it("Should add custodians", async function () {
            await reserveManager.connect(owner).addCustodian("Bank A", user.address);
            const count = await reserveManager.getCustodianCount();
            expect(count).to.equal(1);
        });

        it("Should allow authorized minting", async function () {
            const amount = ethers.parseEther("100");
            const authId = ethers.keccak256(ethers.toUtf8Bytes("auth-001"));

            await reserveManager.connect(owner).authorizeAndMint(user.address, amount, authId);
            expect(await eurium.balanceOf(user.address)).to.equal(amount);
        });

        it("Should enforce daily mint limit", async function () {
            const dailyLimit = await reserveManager.dailyMintLimit();
            const authId1 = ethers.keccak256(ethers.toUtf8Bytes("auth-001"));

            await expect(
                reserveManager.connect(owner).authorizeAndMint(user.address, dailyLimit + 1n, authId1)
            ).to.be.revertedWith("Exceeds daily mint limit");
        });

        it("Should update custodian status", async function () {
            await reserveManager.connect(owner).addCustodian("Bank A", user.address);
            await reserveManager.connect(owner).updateCustodianStatus(0, false);

            const custodian = await reserveManager.custodians(0);
            expect(custodian.active).to.be.false;
        });
    });

    describe("Treasury", function () {
        beforeEach(async function () {
            const WITHDRAWER_ROLE = await treasury.WITHDRAWER_ROLE();
            await treasury.connect(owner).grantRole(WITHDRAWER_ROLE, owner.address);
        });

        it("Should accept native currency deposits", async function () {
            const amount = ethers.parseEther("1");
            await owner.sendTransaction({
                to: await treasury.getAddress(),
                value: amount
            });

            expect(await treasury.getBalance(ethers.ZeroAddress)).to.equal(amount);
        });

        it("Should allow authorized withdrawals", async function () {
            const depositAmount = ethers.parseEther("1");
            await owner.sendTransaction({
                to: await treasury.getAddress(),
                value: depositAmount
            });

            const withdrawAmount = ethers.parseEther("0.5");
            const balanceBefore = await ethers.provider.getBalance(user.address);

            await treasury.connect(owner).withdraw(ethers.ZeroAddress, user.address, withdrawAmount);

            const balanceAfter = await ethers.provider.getBalance(user.address);
            expect(balanceAfter - balanceBefore).to.equal(withdrawAmount);
        });

        it("Should enforce daily withdrawal limits", async function () {
            // First, lower the daily limit to something testable
            const newLimit = ethers.parseEther("1");
            await treasury.connect(owner).setDailyWithdrawalLimit(newLimit);

            // Deposit enough to test the limit
            const depositAmount = ethers.parseEther("2");
            await owner.sendTransaction({
                to: await treasury.getAddress(),
                value: depositAmount
            });

            // Try to withdraw more than the daily limit
            await expect(
                treasury.connect(owner).withdraw(ethers.ZeroAddress, user.address, newLimit + 1n)
            ).to.be.revertedWith("Exceeds daily withdrawal limit");
        });

        it("Should allow emergency withdrawals by admin", async function () {
            const amount = ethers.parseEther("1");
            await owner.sendTransaction({
                to: await treasury.getAddress(),
                value: amount
            });

            await treasury.connect(owner).emergencyWithdraw(ethers.ZeroAddress, user.address, amount);
            expect(await treasury.getBalance(ethers.ZeroAddress)).to.equal(0);
        });
    });
});
