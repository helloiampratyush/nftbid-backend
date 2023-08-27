// migrations/01_deploy_basic_nft.js
const { ethers, network } = require("hardhat");
const { verify } = require("../utils/verify");
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const nft01 = await deploy("BasicNft", {
    from: deployer,
    args: [], // Provide constructor arguments if any
    log: true,
  });
  const nft02 = await deploy("BasicNft2", {
    from: deployer,
    args: [], // Provide constructor arguments if any
    log: true,
  });
  const nft03 = await deploy("BasicNft3", {
    from: deployer,
    args: [], // Provide constructor arguments if any
    log: true,
  });
  if (network.config.chainId != 31337) {
    await verify(nft01.address, []);
    await verify(nft02.address, []);
    await verify(nft03.address, []);
  }
};
module.exports.tags = ["all", "nft01", "nft02", "nft03"];
