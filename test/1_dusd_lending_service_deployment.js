    // TODO
    //  should send dai to account 1 and account 2 before this whole tests - Done
    //  should get yDai balance of account - DaiLending Adapter - Done
    //  should get dai balance of account - DaiLending Adapter - Done
    //  should save - DaiLending Service
    //  should withdraw - DaiLending Service
    //  should withdraw by shares - DaiLending Service
    //  should withdraw by exact amount - DaiLending Service

console.log("********************** Running DEFI Lending Deployments Test *****************************");
const Web3 = require('web3');
const { assert } = require('console');
const web3 = new Web3("HTTP://127.0.0.1:8545");

const DUSDLendingAdapterContract = artifacts.require("ibDUSDLendingAdapter");
const DUSDLendingServiceContract = artifacts.require("ibDUSDLendingService");


/** External contracts definition for DAI and YDAI
 *  1. I have unlocked an address from Ganache-cli that contains a lot of dai
 *  2. We will use the DAI contract to enable transfer and also balance checking of the generated accounts
 *  3. We will use the YDAI contract to enable transfer and also balance checking of the generated accounts
*/
const DaiContractABI = require("../abi/DAIContract.json");
const YDaiContractABI = require("../abi/YDAIContractABI.json");

const DaiContractAddress = "0x5BC25f649fc4e26069dDF4cF4010F9f706c23831";
const yDaiContractAddress = "0x42600c4f6d84Aa4D246a3957994da411FA8A4E1c"
const unlockedAddress = "0xF0048b6232E8e8761EEB1B2b68B685D853916b9c";   //  Has lots of DAI

const daiContract = new web3.eth.Contract(DaiContractABI,DaiContractAddress);
const yDaiContract = new web3.eth.Contract(YDaiContractABI,yDaiContractAddress);


var account1;   
var account2;

var account1Balance;
var account2Balance;


//  Send Dai from our constant unlocked address to any recipient
async function sendDai(amount, recipient){

    var amountToSend = BigInt(amount); //  1000 Dai

    console.log(`Sending  ${ amountToSend } x 10^-18 Dai to  ${recipient}`);

    await daiContract.methods.transfer(recipient,amountToSend).send({from: unlockedAddress});

    let recipientBalance = await daiContract.methods.balanceOf(recipient).call();
    
    console.log(`Recipient: ${recipient} DAI Balance: ${recipientBalance}`);


}

//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveDai(spender,  owner,  amount){

    await daiContract.methods.approve(spender,amount).send({from: owner});

    console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 Dai by Owner:  ${owner}`);

};

//  Approve a smart contract address or normal address to spend on behalf of the owner
async function approveYDai(spender,  owner,  amount){

    await yDaiContract.methods.approve(spender,amount).send({from: owner});

    console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 YDai by Owner:  ${owner}`);

};


contract('DaiLendingService', () => {
    let dusdLendingAdapterContract = null;
    let dusdLendingService = null;

    before(async () =>{
        dusdLendingAdapterContract = await DUSDLendingAdapterContract.deployed();
        dusdLendingService = await DUSDLendingServiceContract.deployed();

        //  Update the adapter
        await dusdLendingService.updateAdapter(dusdLendingAdapterContract.address);


        //  Get the addresses and Balances of at least 2 accounts to be used in the test
        //  Send DAI to the addresses
        web3.eth.getAccounts().then(function(accounts){

            account1 = accounts[0];
            account2 = accounts[1];

            //  send money from the unlocked dai address to accounts 1 and 2
            var amountToSend = BigInt(1000000000000000000); //   10,000 Dai

            //  get the eth balance of the accounts
            web3.eth.getBalance(account1, function(err, result) {
                if (err) {
                    console.log(err)
                } else {
        
                    account1Balance = web3.utils.fromWei(result, "ether");
                    console.log("Account 1: "+ accounts[0] + "  Balance: " + account1Balance + " ETH");
                    sendDai(amountToSend,account1);

                }
            });
    
            web3.eth.getBalance(account2, function(err, result) {
                if (err) {
                    console.log(err)
                } else {
                    account2Balance = web3.utils.fromWei(result, "ether");
                    console.log("Account 2: "+ accounts[1] + "  Balance: " + account2Balance + " ETH");
                    sendDai(amountToSend,account2);                              

                }
            });


        });


    });

    it('DaiLendingService Contract: Should deploy  smart contract properly', async () => {
        console.log(dusdLendingService.address);
        assert(dusdLendingService.address !== '');
    });

    
    it('DaiLendingService Contract: Should Get Current Price Per Full Share', async () => {

        var price = await dusdLendingService.GetPricePerFullShare();
        var value = BigInt(price);

        console.log(value);
        assert(value > 0);
    });

    it('Should ensure we have ETH on each generated account', async () => {
        
        assert(account1Balance > 0);
        assert(account2Balance > 0);

    });

    it('DaiLendingService Contract: Should Save some Dai in the Yearn Finance', async() => {

        //  First we have to approve the adapter to spend money on behlaf of the owner of the DAI, in this case account 1 and 2
        var approvedAmountToSpend = BigInt(1000000000000000000); //   10,000 Dai
        await approveDai(dusdLendingAdapterContract.address,account1,approvedAmountToSpend);
        await approveDai(dusdLendingAdapterContract.address,account2,approvedAmountToSpend);

        //  Save 5,000 dai
        //  Amount is deducted from sender which is account 1
        //  TODO: find a way to make request from account 2
        var approvedAmountToSave = "1000000000000000000"; // NOTE: Use amount as string. It is a bug from web3.js. If you use BigInt it will fail
        await dusdLendingService.Save(approvedAmountToSave); 

        //  Get YDai Shares balance and Dai balance after saving
        var YDaibalanceAfterSaving = BigInt(await dusdLendingAdapterContract.GetIBDUSDBalance(account1));
        var DaiBalanceAfterSaving = BigInt(await dusdLendingAdapterContract.GetDUSDBalance(account1));


        console.log("DaiLendingService Contract - YDai Balance After Saving: "+YDaibalanceAfterSaving);
        console.log("DaiLendingService Contract - Dai Balance After Saving: "+DaiBalanceAfterSaving);

        assert(YDaibalanceAfterSaving > 0);
        assert(DaiBalanceAfterSaving > 0);
    });


    it('DaiLendingService Contract: Should Withdraw Dai From Yearn Finance', async() => {

        //  Get YDai Shares balance
        var yDaiBlanceBeforeWithdrawal = BigInt(await dusdLendingAdapterContract.GetIBDUSDBalance(account1));
        
        //  Run this test only if we have yDai shares already in the address
        if(yDaiBlanceBeforeWithdrawal > 0){
            
            //  First we have to approve the adapter to spend money on behlaf of the owner of the YDAI, in this case account 1 and 2
            var approvedAmountToSpend = BigInt(1000000000000000000); //   10,000 YDai
            await approveYDai(dusdLendingAdapterContract.address,account1,approvedAmountToSpend);
            await approveYDai(dusdLendingAdapterContract.address,account2,approvedAmountToSpend);

            //  Get Dai balance before withdrawal
            var balanceBeforeWithdrawal = BigInt(await dusdLendingAdapterContract.GetDUSDBalance(account1));

            //  Withdraw 2,000  Dai. 
            //  TODO: find a way to make request from account 2
            var approvedAmountToWithdraw = "1000000000000000000"; // NOTE: Use amount as string. It is a bug from web3.js. If you use BigInt it will fail
            await dusdLendingService.Withdraw(approvedAmountToWithdraw);

            //  Get Dai balance after withdrawal
            var balanceAfterWithdrawal = BigInt(await dusdLendingAdapterContract.GetDUSDBalance(account1));
            
            assert(balanceBeforeWithdrawal > 0);
            assert(balanceAfterWithdrawal > 0);
            assert(balanceAfterWithdrawal > balanceBeforeWithdrawal);
            console.log("balance before withdrawal: " + balanceBeforeWithdrawal);
            console.log("Withdrawing:  " + approvedAmountToWithdraw + " DAI");
            console.log("balance after withdrawal: " + balanceAfterWithdrawal);
        }else{
            console.log("Savings has not been made!!!")
        }

    });

    it('DaiLendingService Contract: Should Withdraw By Specifying YDaiShares Amount and DAI Amount', async() => {
        //  This function is used by EsusuAdapter when you need to only specify the share amount of the cycle and then
        //  the dai amount that should be sent to a member of that cycle. 

        //  Get YDai Shares balance
        var yDaiBlanceBeforeWithdrawal = BigInt(await dusdLendingAdapterContract.GetIBDUSDBalance(account1));
        
        //  Run this test only if we have yDai shares already in the address
        if(yDaiBlanceBeforeWithdrawal > 0){
            
            //  First we have to approve the adapter to spend money on behlaf of the owner of the YDAI, in this case account 1 and 2
            var approvedAmountToSpend = BigInt(1000000000000000000); //   10,000 YDai
            await approveYDai(dusdLendingAdapterContract.address,account1,approvedAmountToSpend);
            await approveYDai(dusdLendingAdapterContract.address,account2,approvedAmountToSpend);

            //  Get Dai balance before withdrawal
            var balanceBeforeWithdrawal = BigInt(await dusdLendingAdapterContract.GetDUSDBalance(account1));

            //  Withdraw 1,000 Dai. 
            //  TODO: find a way to make request from account 2
            var approvedAmountToWithdrawInDai = "1000000000000000000"; // NOTE: Use amount as string. It is a bug from web3.js. If you use BigInt it will fail
            var YDaibalanceOfAddress = BigInt(await dusdLendingAdapterContract.GetIBDUSDBalance(account1));
            await dusdLendingService.WithdrawByShares(approvedAmountToWithdrawInDai,YDaibalanceOfAddress.toString() );

            //  Get Dai balance after withdrawal
            var balanceAfterWithdrawal = BigInt(await dusdLendingAdapterContract.GetDUSDBalance(account1));
            
            assert(balanceBeforeWithdrawal > 0);
            assert(balanceAfterWithdrawal > 0);
            assert(balanceAfterWithdrawal > balanceBeforeWithdrawal);
            console.log("balance before withdrawal by shares: " + balanceBeforeWithdrawal);
            console.log("Withdrawing:  " + approvedAmountToWithdrawInDai + " DAI");
            console.log("balance after withdrawal by shares: " + balanceAfterWithdrawal);  

        }else{
            console.log("Savings has not been made!!!")
        }

    });

    it('DaiLendingService Contract: Should Withdraw By Specifying YDaiShares Amount Only', async() => {
        //  This function is used when you need to only specify the share amount 

        //  Get YDai Shares balance
        var yDaiBlanceBeforeWithdrawal = BigInt(await dusdLendingAdapterContract.GetIBDUSDBalance(account1));
        
        //  Run this test only if we have yDai shares already in the address
        if(yDaiBlanceBeforeWithdrawal > 0){
            
            //  First we have to approve the adapter to spend money on behlaf of the owner of the YDAI, in this case account 1 and 2
            var approvedAmountToSpend = BigInt(1000000000000000000); //   10,000 YDai
            await approveYDai(dusdLendingAdapterContract.address,account1,approvedAmountToSpend);
            await approveYDai(dusdLendingAdapterContract.address,account2,approvedAmountToSpend);

            //  Get Dai balance before withdrawal
            var balanceBeforeWithdrawal = BigInt(await dusdLendingAdapterContract.GetDUSDBalance(account1));

            //  Withdraw  
            //  TODO: find a way to make request from account 2
            var YDaibalanceOfAddress = BigInt(await dusdLendingAdapterContract.GetIBDUSDBalance(account1));
            await dusdLendingService.WithdrawBySharesOnly(YDaibalanceOfAddress.toString());

            //  Get Dai balance after withdrawal
            var balanceAfterWithdrawal = BigInt(await dusdLendingAdapterContract.GetDUSDBalance(account1));
            
            assert(balanceBeforeWithdrawal > 0);
            assert(balanceAfterWithdrawal > 0);
            assert(balanceAfterWithdrawal > balanceBeforeWithdrawal);
            console.log("balance before withdrawal by shares: " + balanceBeforeWithdrawal);
            console.log("Withdrawing Everything Plus Interest :D");
            console.log("balance after withdrawal by shares: " + balanceAfterWithdrawal);  

        }else{
            console.log("Savings has not been made!!!")
        }

    });
});
