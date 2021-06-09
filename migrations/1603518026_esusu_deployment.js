
//  1. Ensure you have done truffle compile to ensure the contract ABI has been added to the artifact
const DUSDLendingAdapterContract = artifacts.require("ibDUSDLendingAdapter");
const DUSDLendingServiceContract = artifacts.require("ibDUSDLendingService");
const GroupsContract = artifacts.require('Groups');
const TreasuryContract = artifacts.require('Treasury');
const CyclesContract = artifacts.require("Cycles");
const ClientRecordContract = artifacts.require("ClientRecord");
const SavingsConfigContract = artifacts.require('SavingsConfig');
const XendFinanceIndividual_Yearn_V1Contract = artifacts.require(
  "XendFinanceIndividual_Yearn_V1"
);
const XendFinanceGroup_Yearn_V1Contract = artifacts.require('XendFinanceGroup_Yearn_V1')
const RewardBridgeContract = artifacts.require('RewardBridge');

const EsusuServiceContract = artifacts.require('EsusuService');
const RewardConfigContract = artifacts.require('RewardConfig');
const EsusuAdapterContract = artifacts.require('EsusuAdapter');
const EsusuAdapterWithdrawalDelegateContract = artifacts.require('EsusuAdapterWithdrawalDelegate');
const EsusuStorageContract = artifacts.require('EsusuStorage');
const XendFinanceGroup_Yearn_V1Helpers  = artifacts.require("XendFinanceGroup_Yearn_V1Helpers");

const StakedTokenContractAddress = "0xe9e7cea3dedca5984780bafc599bd69add087d56";  // This is a custom BUSD for ForTube, you will not find it on BSC Faucet
const DerivativeTokenContractAddress = "0x4eac4c4e9050464067d673102f8e24b2fcceb350";  // This is the FToken shares a user will receive when they deposit BUSD



module.exports = function (deployer) {

  console.log("********************** Running Esusu Migrations *****************************");

  deployer.then(async () => {


     await deployer.deploy(GroupsContract);

     await deployer.deploy(TreasuryContract);
     await deployer.deploy(CyclesContract);

     await deployer.deploy(ClientRecordContract);
 

     await deployer.deploy(SavingsConfigContract);

     await deployer.deploy(DUSDLendingServiceContract);

     await deployer.deploy(DUSDLendingAdapterContract,DUSDLendingServiceContract.address);


     await deployer.deploy(EsusuServiceContract);

     await deployer.deploy(RewardConfigContract,EsusuServiceContract.address, GroupsContract.address);

     await deployer.deploy(EsusuStorageContract);
     await deployer.deploy(RewardBridgeContract,'0x4a080377f83d669d7bb83b3184a8a5e61b500608');

    //  address payable serviceContract, address esusuStorageContract, address esusuAdapterContract,
    //                 string memory feeRuleKey, address treasuryContract, address rewardConfigContract, address xendTokenContract

     await deployer.deploy(EsusuAdapterContract,
                            EsusuServiceContract.address,
                            GroupsContract.address,
                            EsusuStorageContract.address);

      await deployer.deploy(EsusuAdapterWithdrawalDelegateContract,
                              EsusuServiceContract.address,
                              EsusuStorageContract.address,
                              EsusuAdapterContract.address,
                              "esusufee",
                              TreasuryContract.address,
                              RewardConfigContract.address,
                              RewardBridgeContract.address,
                              SavingsConfigContract.address);

                              await deployer.deploy(XendFinanceGroup_Yearn_V1Helpers,                               
                                GroupsContract.address,
                                CyclesContract.address,                              
                                )

                              await deployer.deploy(
                                XendFinanceIndividual_Yearn_V1Contract,
                                DUSDLendingServiceContract.address,
                                StakedTokenContractAddress,
                                ClientRecordContract.address,
                                GroupsContract.address,
                                SavingsConfigContract.address,
                                DerivativeTokenContractAddress,
                                RewardConfigContract.address,
                                TreasuryContract.address,
                                RewardBridgeContract.address
                              );

                              await deployer.deploy(XendFinanceGroup_Yearn_V1Contract, 
                                DUSDLendingServiceContract.address,
                                StakedTokenContractAddress,
                                GroupsContract.address,
                                CyclesContract.address,
                                TreasuryContract.address,
                                SavingsConfigContract.address,
                                RewardConfigContract.address,
                                RewardBridgeContract.address,
                                DerivativeTokenContractAddress,
                                XendFinanceGroup_Yearn_V1Helpers.address
                                )

     console.log("Groups Contract address: "+GroupsContract.address);
     console.log("Cycles Contract address", "",  CyclesContract.address);


     console.log("Treasury Contract address: "+TreasuryContract.address);

     console.log("SavingsConfig Contract address: "+SavingsConfigContract.address);

     console.log("DUSDLendingServiceContract Contract address: " + DUSDLendingServiceContract.address);

     console.log("DUSDLendingAdapterContract Contract address: "+DUSDLendingAdapterContract.address );

     console.log("XendToken Contract address: "+RewardBridgeContract.address );


     console.log("EsusuService Contract address: "+EsusuServiceContract.address );

     console.log("EsusuStorage Contract address: "+EsusuStorageContract.address );

     console.log("EsusuAdapterWithdrawalDelegate Contract address: "+EsusuAdapterWithdrawalDelegateContract.address );

     console.log("RewardConfig Contract address: "+RewardConfigContract.address );

     console.log("EsusuAdapter Contract address: "+EsusuAdapterContract.address );

     console.log("ClientRecordContract address", ClientRecordContract.address);

     console.log("Xend finance indidvual contract", XendFinanceIndividual_Yearn_V1Contract.address)
     console.log("Xend finance group contract", XendFinanceGroup_Yearn_V1Contract.address)



     let savingsConfigContract = null;
    

     savingsConfigContract = await SavingsConfigContract.deployed();
  
   
    
    await savingsConfigContract.createRule("XEND_FEE_PRECISION",0,0,100,1);

    await savingsConfigContract.createRule("PERCENTAGE_AS_PENALTY",0,0,10,1);

    await savingsConfigContract.createRule("PERCENTAGE_PAYOUT_TO_USERS",0,0,150,1);

    await savingsConfigContract.createRule("XEND_FINANCE_COMMISION_DIVIDEND",0,0,200,1);
    await savingsConfigContract.createRule("XEND_FINANCE_COMMISION_FLEXIBLE_DIVIDEND",0,0,1,1);


 
  })

};
