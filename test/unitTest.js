const { deployments, getNamedAccounts, ethers } = require("hardhat");
const { assert, expect } = require("chai");

describe("nftMarketBid", function () {
  let deployer, nftContract, mainContract, tokenId, minPrice;

  beforeEach(async function () {
    deployer = (await getNamedAccounts()).deployer;
    const prob = await deployments.fixture(["all"]);
    nftContract = await ethers.getContract("BasicNft", deployer);
    mainContract = await ethers.getContract("nftbid", deployer);
    tokenId = 0;
    minPrice = ethers.utils.parseEther("0.01");
    const minting = await nftContract.mintNft();
    const approveToMarket = await nftContract.approve(
      mainContract.address,
      tokenId
    );
  });

  describe("list item and allow bid", function () {
    it("only respective nft owner can allow bid", async function () {
      const txAsk1 = await mainContract.listItem(
        nftContract.address,
        tokenId,
        minPrice
      );
      const Accounts = await ethers.getSigners();
      const account2ConnectedContract = await mainContract.connect(Accounts[2]);
      await expect(
        account2ConnectedContract.allowBid(
          nftContract.address,
          tokenId,
          minPrice,
          3600 // timeOfBid in seconds
        )
      ).to.be.revertedWith("nftbid__notOwner");
    });
  });
  describe("bidding", function () {
    it("who bid more will get his name", async function () {
      const txAsk1 = await mainContract.listItem(
        nftContract.address,
        tokenId,
        minPrice
      );
      const accounts = await ethers.getSigners();
      const bidAllowed = await mainContract.allowBid(
        nftContract.address,
        tokenId,
        minPrice,
        3600
      );
      const gettime = await mainContract.getTimeStatus(
        nftContract.address,
        tokenId
      );
      const startTime = gettime.bidStartTime.toString();
      const endTime = gettime.bidEndTime.toString();
      const remainTime = endTime - startTime;
      assert.equal(remainTime.toString(), "3600");
      const bidAmount1 = ethers.utils.parseEther("0.03");
      const p1 = await mainContract.connect(accounts[1]);
      const p2 = await mainContract.connect(accounts[2]);
      const p1bid = await p1.bidding(nftContract.address, tokenId, bidAmount1);
      const bidAmount2 = ethers.utils.parseEther("0.05");
      const p2bid = await p2.bidding(nftContract.address, tokenId, bidAmount2);
      const nftStatus = await mainContract.getstatusOfList(
        nftContract.address,
        tokenId
      );

      await network.provider.send("evm_increaseTime", [remainTime]);

      const paid = await p2.highestBidderPaid(nftContract.address, tokenId, {
        value: bidAmount2,
      });

      const getEarning = await mainContract.getGainedProfitAmount();

      assert.equal(getEarning.toString(), bidAmount2.toString());
    });
  });
});
