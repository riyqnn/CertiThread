// Script to deploy the ProductSeriesNFT contract
import { ethers } from "hardhat";

async function main() {
  try {
    // Retrieve the current network information (e.g., hardhat, monadTestnet)
    const network = (await ethers.provider.getNetwork()).name;
    console.log(`Deploying ProductSeriesNFT to ${network} network...`);

    // Load the ContractFactory compiled from Solidity source code
    const ProductSeriesNFT =
      await ethers.getContractFactory("ProductSeriesNFT");

    // Specify the deployed address of the BrandVerificationNFT contract
    // This address is passed to the ProductSeriesNFT constructor for verification dependency
    const verificationContractAddress =
      "0x8aCF80674385Bc8e7dd91dddA56A8e6464eBe35a";

    // Start the deployment transaction (contract creation)
    console.log("Initiating deployment transaction...");
    const productSeriesNFT = await ProductSeriesNFT.deploy(
      verificationContractAddress
    );

    // Wait until the deployment transaction is mined and confirmed
    console.log("Waiting for deployment transaction confirmation...");
    await productSeriesNFT.waitForDeployment();

    // Get the deployed contract address on the network
    const contractAddress = await productSeriesNFT.getAddress();
    console.log(
      `ProductSeriesNFT deployed successfully to: ${contractAddress}`
    );

    // Print a convenient link to view the contract in the Monad Testnet Explorer (if applicable)
    if (network === "monadTestnet") {
      console.log(`\nView your contract on Monad Testnet Explorer:`);
      console.log(
        `https://testnet.monadexplorer.com/address/${contractAddress}`
      );
    }

    // Return the contract address for further use if needed
    return contractAddress;
  } catch (error) {
    // Log any unexpected errors during deployment
    console.error("Deployment failed with error:");
    console.error(error);
    process.exitCode = 1;
  }
}

// Pattern to catch unhandled promise rejections and exit the process gracefully
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
