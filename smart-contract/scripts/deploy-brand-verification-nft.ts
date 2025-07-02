// Script to deploy the BrandVerificationNFT contract
import { ethers } from "hardhat";

async function main() {
  try {
    // Retrieve the current network information (e.g., hardhat, monadTestnet)
    const network = (await ethers.provider.getNetwork()).name;
    console.log(`Deploying BrandVerificationNFT to ${network} network...`);

    // Load the ContractFactory compiled from Solidity source code
    const BrandVerificationNFT = await ethers.getContractFactory(
      "BrandVerificationNFT"
    );

    // Start the deployment transaction (contract creation)
    console.log("Initiating deployment transaction...");
    const brandVerificationNFT = await BrandVerificationNFT.deploy();

    // Wait until the deployment transaction is mined and confirmed
    console.log("Waiting for deployment transaction confirmation...");
    await brandVerificationNFT.waitForDeployment();

    // Get the deployed contract address on the network
    const contractAddress = await brandVerificationNFT.getAddress();
    console.log(
      `BrandVerificationNFT deployed successfully to: ${contractAddress}`
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
