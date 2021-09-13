const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { BigNumber } = ethers;

describe("DAO tests", function () {
    let owner;
    let guest1;
    let guest2;
    let guest3;
    
    before(async function () {
        this.ComicDAO = await ethers.getContractFactory('ComicDAO');
        this.ComicToken = await ethers.getContractFactory('ComicToken');
        this.MajorGovernor = await ethers.getContractFactory('ComicMajorGovernor');
        this.MinorGovernor = await ethers.getContractFactory('ComicMinorGovernor');
    });

    beforeEach(async function () {
        [owner, guest1, guest2, guest3] = await ethers.getSigners();

        // deployed dao contract
        this.dao = await this.ComicDAO.deploy();
        await this.dao.deployed();
        this.ct = await this.ComicToken.deploy();
        this.token = await this.ct.attach(await this.dao.getComicToken());
        this.majgov = await this.MajorGovernor.deploy(this.token.address);
        this.mingov = await this.MinorGovernor.deploy(this.token.address);
        this.majGovernor = await this.majgov.attach(await this.dao.getMajorGovernor());
        this.minGovernor = await this.mingov.attach(await this.dao.getMinorGovernor());

        await this.dao.connect(guest2).contribute({ value:150000000000 });
        await this.dao.connect(guest1).contribute({ value:300000000000 });
        await this.dao.connect(guest3).contribute({ value:400000000000 });
        await this.dao.connect(guest1).redeemComicToken();
        await this.dao.connect(guest2).redeemComicToken();
        await this.dao.connect(guest3).redeemComicToken();

    })

    it("test whether artists and writers can propose", async function () {
        console.log(await this.token.balanceOf(guest1.address));
    });
    
});