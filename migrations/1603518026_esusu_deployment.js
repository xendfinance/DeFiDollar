
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
const XendTokenContract = artifacts.require('XendToken');
const EsusuServiceContract = artifacts.require('EsusuService');
const RewardConfigContract = artifacts.require('RewardConfig');
const EsusuAdapterContract = artifacts.require('EsusuAdapter');
const EsusuAdapterWithdrawalDelegateContract = artifacts.require('EsusuAdapterWithdrawalDelegate');
const EsusuStorageContract = artifacts.require('EsusuStorage');
const XendFinanceGroup_Yearn_V1Helpers  = artifacts.require("XendFinanceGroup_Yearn_V1Helpers");

const StakedTokenContractAddress = "0x5BC25f649fc4e26069dDF4cF4010F9f706c23831";  // This is a custom BUSD for ForTube, you will not find it on BSC Faucet
const DerivativeTokenContractAddress = "0x42600c4f6d84Aa4D246a3957994da411FA8A4E1c";  // This is the FToken shares a user will receive when they deposit BUSD



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

     await deployer.deploy(XendTokenContract, "Xend Token", "$XEND","18","200000000000000000000000000");

     await deployer.deploy(EsusuServiceContract);

     await deployer.deploy(RewardConfigContract,EsusuServiceContract.address, GroupsContract.address);

     await deployer.deploy(EsusuStorageContract);

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
                              XendTokenContract.address,
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
                                XendTokenContract.address
                              );

                              await deployer.deploy(XendFinanceGroup_Yearn_V1Contract, 
                                DUSDLendingServiceContract.address,
                                StakedTokenContractAddress,
                                GroupsContract.address,
                                CyclesContract.address,
                                TreasuryContract.address,
                                SavingsConfigContract.address,
                                RewardConfigContract.address,
                                XendTokenContract.address,
                                DerivativeTokenContractAddress,
                                XendFinanceGroup_Yearn_V1Helpers.address
                                )

     console.log("Groups Contract address: "+GroupsContract.address);
     console.log("Cycles Contract address", "",  CyclesContract.address);


     console.log("Treasury Contract address: "+TreasuryContract.address);

     console.log("SavingsConfig Contract address: "+SavingsConfigContract.address);

     console.log("DUSDLendingServiceContract Contract address: " + DUSDLendingServiceContract.address);

     console.log("DUSDLendingAdapterContract Contract address: "+DUSDLendingAdapterContract.address );

     console.log("XendToken Contract address: "+XendTokenContract.address );

     console.log("EsusuService Contract address: "+EsusuServiceContract.address );

     console.log("EsusuStorage Contract address: "+EsusuStorageContract.address );

     console.log("EsusuAdapterWithdrawalDelegate Contract address: "+EsusuAdapterWithdrawalDelegateContract.address );

     console.log("RewardConfig Contract address: "+RewardConfigContract.address );

     console.log("EsusuAdapter Contract address: "+EsusuAdapterContract.address );

     console.log("ClientRecordContract address", ClientRecordContract.address);

     console.log("Xend finance indidvual contract", XendFinanceIndividual_Yearn_V1Contract.address)
     console.log("Xend finance group contract", XendFinanceGroup_Yearn_V1Contract.address)


     let dusdLendingAdapterContract = null;
     let dusdLendingService = null;
     let savingsConfigContract = null;
     let esusuAdapterContract = null;
     let esusuServiceContract = null;
     let groupsContract = null;
     let xendTokenContract = null;
     let esusuAdapterWithdrawalDelegateContract = null;
     let esusuStorageContract = null;
     let rewardConfigContract = null;

     savingsConfigContract = await SavingsConfigContract.deployed();
     dusdLendingAdapterContract = await DUSDLendingAdapterContract.deployed();
     dusdLendingService = await DUSDLendingServiceContract.deployed();
     esusuAdapterContract = await EsusuAdapterContract.deployed();
     esusuServiceContract = await EsusuServiceContract.deployed();
     groupsContract = await GroupsContract.deployed();
     xendTokenContract = await XendTokenContract.deployed();
     esusuAdapterWithdrawalDelegateContract = await EsusuAdapterWithdrawalDelegateContract.deployed();
     esusuStorageContract = await EsusuStorageContract.deployed();
     rewardConfigContract = await RewardConfigContract.deployed();
   
     await savingsConfigContract.createRule(
       "XEND_FINANCE_COMMISION_DIVISOR",
       0,
       0,
       100,
       1
     );
 
     await savingsConfigContract.createRule(
       "XEND_FINANCE_COMMISION_DIVIDEND",
       0,
       0,
       1,
       1
     );
 
     await savingsConfigContract.createRule(
       "PERCENTAGE_PAYOUT_TO_USERS",
       0,
       0,
       0,
       1
     );
 
     await savingsConfigContract.createRule("PERCENTAGE_AS_PENALTY", 0, 0, 1, 1);

 
  })

};
