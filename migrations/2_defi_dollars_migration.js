
//  1. Ensure you have done truffle compile to ensure the contract ABI has been added to the artifact
const DUSDLendingAdapterContract = artifacts.require("ibDUSDLendingAdapter");
const DUSDLendingServiceContract = artifacts.require("ibDUSDLendingService");

module.exports = function (deployer) {
  
  console.log("********************** Running Defi Dollars Lending Migrations *****************************");

  deployer.then(async () => {

     await deployer.deploy(DUSDLendingServiceContract);

     await deployer.deploy(DUSDLendingAdapterContract,DUSDLendingServiceContract.address);

     console.log("DaiLendingService Contract address: " + DUSDLendingServiceContract.address);

     console.log("DaiLendingAdapterContract address: "+DUSDLendingAdapterContract.address );
  })
  
};


