require("@nomiclabs/hardhat-ethers");
const { BigNumber } = require("@ethersproject/bignumber");
require("dotenv").config();
var fs = require("fs");
const util = require("util");
var ethers = require("ethers");
const { shallowCopy, _toEscapedUtf8String } = require("ethers/lib/utils");
const fsPromises = fs.promises;

// The path to the contract ABI
const ABI_FILE_PATH = "./scripts/LetterBoxingv2.json";
// The address from the deployed smart contract
const DEPLOYED_CONTRACT_ADDRESS = "0x9892ad54986aA0ec1554557dD5dAF9E2d42dD480";

// load ABI from build artifacts
async function getAbi() {
  const data = await fsPromises.readFile(ABI_FILE_PATH, "utf8");
  const abi = JSON.parse(data)["abi"];
  //console.log(abi);
  return abi;
}

async function main() {
  const { BLASTAPI_PROJECT_ID } = process.env;
  let provider = ethers.getDefaultProvider(
    `https://moonbase-alpha.blastapi.io/${BLASTAPI_PROJECT_ID}`
  );
  const abi = await getAbi();

  // WRITE operations require a signer
  const { PRIVATE_KEY_MOONBASE } = process.env;
  let signer = new ethers.Wallet(PRIVATE_KEY_MOONBASE, provider);
  const lbcontract = new ethers.Contract(
    DEPLOYED_CONTRACT_ADDRESS,
    abi,
    signer
  );
  //   let fee = await lbcontract.feeGetter();

  //   console.log("fee getter tests connection: ", fee.toNumber());
  //   await lbcontract.mintStamp(
  //     "0x7d807d9daFfbFb89C9B2BFa6a7548A7A8557A013",
  //     "https://storageapi.fleek.co/8d3169a1-da25-443a-8e1f-a83ff25c6b1c-bucket/narrativetrails/letterbox-metadata2"
  //   );
  //   console.log("stamp: ", stamp);
  //   await lbcontract.mintLetterbox(
  //     "0x609cB97e273011Ab5D56e73cF880D2880F9922f6",
  //     "https://storageapi.fleek.co/8d3169a1-da25-443a-8e1f-a83ff25c6b1c-bucket/narrativetrails/letterbox-metadata"
  //   );

  let letterboxerAddress = "0x609cB97e273011Ab5D56e73cF880D2880F9922f6";
  let stamperAddress = "0x7d807d9daFfbFb89C9B2BFa6a7548A7A8557A013";

  //next set of tests
  //
  //   let letterboxesbyOwner = await lbcontract.letterboxesHeldBy(
  //     letterboxerAddress
  //   );

  //   console.log("letterboxes by owner: ");
  //   for (let i = 0; i < letterboxesbyOwner.length; i++) {
  //     console.log("i: ", i, "letterbox id: ", letterboxesbyOwner[i].toNumber());
  //   }

  //   let letterbox0 = letterboxesbyOwner[0].toNumber();

  //   //   await lbcontract.stampToLetterbox(stamperAddress, letterbox0, true);
  //   //   await lbcontract.letterboxToStamp(stamperAddress, letterbox0);

  //   let stamp = await lbcontract.stampHeldBy(stamperAddress);
  //   console.log("Stamp id is : ", stamp.toNumber());
  //   let letterboxResources = await lbcontract.getFullResources(letterbox0);
  //   console.log("Letterbox resource length is : ", letterboxResources.length);
  //   console.log(
  //     "Letterbox resource 1 (new addition) has metadataURI: ",
  //     letterboxResources[1].metadataURI
  //   );

  //another set
  let stamp = await lbcontract.stampHeldBy(stamperAddress);
  console.log("Stamp id is : ", stamp.toNumber());
  let stampResources = await lbcontract.getFullResources(stamp.toNumber());
  console.log("Letterbox resource length is : ", stampResources.length);
  console.log(
    "Letterbox resource 1 (new addition) has metadataURI: ",
    stampResources[1].metadataURI
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
