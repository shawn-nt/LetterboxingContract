//const { ethers } = require("hardhat");
const { id } = require("ethers/lib/utils");
const hre = require("hardhat");
const { string } = require("hardhat/internal/core/params/argumentTypes");
const { BigNumber } = require("@ethersproject/bignumber");
const { Contract } = require("ethers");

async function main() {
  //comment out to avoid accidental extra deploys
  const StampMinter = await hre.ethers.getContractFactory("LetterBoxingv2");
  console.log("Deploying contract...");
  const lbcontract = await StampMinter.deploy();
  console.group("letterbox contract deployed to: ", lbcontract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
