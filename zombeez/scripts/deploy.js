// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Zombeez = await hre.ethers.getContractFactory("Zombeez");
  const zombeez = await Zombeez.deploy("ZOMBEEZ", "ZOMBZ", "ipfs://...", "0xc410203efee0f63ea0c52cfa96989359194bf32608def37cc8b5b7e4cd70304c");

  await zombeez.deployed();

  console.log("Greeter deployed to:", zombeez.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
