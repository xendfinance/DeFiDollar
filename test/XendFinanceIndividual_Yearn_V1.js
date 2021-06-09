const { assert } = require("console");

const Web3 = require('web3');

const web3 = new Web3("HTTP://127.0.0.1:8545");

const GroupsContract = artifacts.require("Groups");

const TreasuryContract = artifacts.require("Treasury");

const CyclesContract = artifacts.require("Cycles");

const utils = require("./helpers/utils");

const ClientRecordContract = artifacts.require("ClientRecord");

const SavingsConfigContract = artifacts.require("SavingsConfig");

const DaiLendingAdapterContract = artifacts.require("ibDUSDLendingAdapter");

const DaiLendingServiceContract = artifacts.require("ibDUSDLendingService");

const XendFinanceIndividual_Yearn_V1 = artifacts.require(
  "XendFinanceIndividual_Yearn_V1"
);

const RewardConfigContract = artifacts.require("RewardConfig");

const RewardBridgeContract = artifacts.require("RewardBridge");


const EsusuServiceContract = artifacts.require("EsusuService");

const DaiContractABI = require('../abi/DaiContract.json');

const YDaiContractABI = require('../abi/YDaiContractABI.json');

const DaiContractAddress = "0xe9e7cea3dedca5984780bafc599bd69add087d56";

const yDaiContractAddress = "0x4eac4c4e9050464067d673102f8e24b2fcceb350";

const daiContract = new web3.eth.Contract(DaiContractABI,DaiContractAddress);
    
const yDaiContract = new web3.eth.Contract(YDaiContractABI,yDaiContractAddress);

const unlockedAddress = "0xEfB826Ab5D566DB9d5Af50e17B0cEc5A60c18AA3";


//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveDai(spender,  owner,  amount){

  await daiContract.methods.approve(spender,amount).send({from: owner});

  console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 Dai by Owner:  ${owner}`);

};


   
//  Send Dai from our constant unlocked address to any recipient
async function sendDai(amount, recipient){
    
  var amountToSend = BigInt(amount); //  1000 Dai

  console.log(`Sending  ${ amountToSend } x 10^-18 Dai to  ${recipient}`);

  await daiContract.methods.transfer(recipient,amountToSend).send({from: unlockedAddress});

  let recipientBalance = await daiContract.methods.balanceOf(recipient).call();
  
  console.log(`Recipient: ${recipient} DAI Balance: ${recipientBalance}`);


}
var account1;
var account2;
var account3;

var account1Balance;
var account2Balance;
var account3Balance;

   



contract("XendFinanceIndividual_Yearn_V1", () => {
  let contractInstance = null;
  let cycleContract = null;
  let groupsContract = null;
  let rewardBridge = null;
  let daiLendingService = null;
  let rewardConfigContract = null;
  let clientRecordContract = null;
  let savingsConfigContract = null;
  let daiLendingAdapter = null;
 

  beforeEach(async () => {

    clientRecordContract = await ClientRecordContract.deployed();
    savingsConfigContract =  await SavingsConfigContract.deployed();
    rewardBridge = await RewardBridgeContract.new('0x4a080377f83d669d7bb83b3184a8a5e61b500608');
    daiLendingService  = await DaiLendingServiceContract.deployed();  
    contractInstance = await XendFinanceIndividual_Yearn_V1.deployed();
    daiLendingAdapter = await DaiLendingAdapterContract.deployed(daiLendingService.address);
    cycleContract = await CyclesContract.deployed();

    groupsContract = await GroupsContract.deployed();
  
    daiLendingService.UpdateAdapter(daiLendingAdapter.address);

    await clientRecordContract.activateStorageOracle(contractInstance.address);
    await groupsContract.activateStorageOracle(contractInstance.address);
    await cycleContract.activateStorageOracle(contractInstance.address);
    await rewardBridge.grantAccess(contractInstance.address);

    let accounts = await web3.eth.getAccounts();
    account1 = accounts[0];
    account2 = accounts[1];
    account3 = accounts[2];

    var amountToSend = BigInt(10000000000000000000); //   10 Dai

    await sendDai(amountToSend,account1);
    await sendDai(amountToSend,account2);
    await sendDai(amountToSend,account3);     
  });


  


      

  it("Should deploy the XendFinanceIndividual_Yearn_V1 smart contracts", async () => {
    assert(contractInstance.address !== "");
  });

  it("should throw error because no client records exist", async () => {
      
      await  utils.shouldThrow(contractInstance.getClientRecord(account2));
      
  })
  it("should check if client records exist", async () => {
      const doesClientRecordExistResult = await contractInstance.doesClientRecordExist(account2);

      assert(doesClientRecordExistResult == false);
  });

   it("should deposit and withdraw", async () => {

      //  Give allowance to the xend finance individual to spend DAI on behalf of account 1 and 2
        var approvedAmountToSpend = BigInt(10000000000000000000); //   10 Dai

        let amountToWithdraw = BigInt(5000000000000000000);
      
        await approveDai(contractInstance.address, account1, approvedAmountToSpend);

        //await clientRecord.createClientRecord(accounts[2], 0, 0, 0, 0, 0, {from : accounts[3]})

       await contractInstance.deposit({from : account1});

  

        const withdrawResult = await contractInstance.withdraw(amountToWithdraw);

        assert(withdrawResult.receipt.status == true, "tx receipt status is true")


   })

   it("should deposit and withdraw in fixed deposit", async () => {

    //  Give allowance to the xend finance individual to spend DAI on behalf of account 1 and 2
      var approvedAmountToSpend = BigInt(10000000000000000000); //   1,000 Dai

    
      await approveDai(contractInstance.address, account1, approvedAmountToSpend);


      let lockPeriodInSeconds  = "1"

      await contractInstance.setMinimumLockPeriod(lockPeriodInSeconds);
 
      await contractInstance.FixedDeposit(lockPeriodInSeconds);

      const waitTime = (seconds) => new Promise(resolve => setTimeout(resolve, seconds * 1000));

      await waitTime(10);

      let withdrawResult = await contractInstance.WithdrawFromFixedDeposit("1");

      assert(withdrawResult.receipt.status == true, "tx receipt status is true")


 })


});
