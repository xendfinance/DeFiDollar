    // console.log("********************** Running Dai Lending Deployments Test *****************************");
    // const Web3 = require('web3');
    // const { assert } = require('console');
    // const web3 = new Web3("HTTP://127.0.0.1:8545");
    
    // const DaiLendingAdapterContract = artifacts.require("DaiLendingAdapter");
    // const DaiLendingServiceContract = artifacts.require("DaiLendingService");
    
    // /** External contracts definition for DAI and YDAI
    //  *  1. I have unlocked an address from Ganache-cli that contains a lot of dai
    //  *  2. We will use the DAI contract to enable transfer and also balance checking of the generated accounts
    //  *  3. We will use the YDAI contract to enable transfer and also balance checking of the generated accounts
    // */
    // const DaiContractABI = require("../abi/DAIContract.json");
    // const YDaiContractABI = require("../abi/YDAIContractABI.json");
    
    // const DaiContractAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    // const yDaiContractAddress = "0xC2cB1040220768554cf699b0d863A3cd4324ce32"
    // const unlockedAddress = "0x1eC32Bfdbdbd40C0D3ec0fe420EBCfEEb2D56917";   //  Has lots of DAI
    
    // const daiContract = new web3.eth.Contract(DaiContractABI,DaiContractAddress);
    // const yDaiContract = new web3.eth.Contract(YDaiContractABI,yDaiContractAddress);
    
    
    // var account1;   
    // var account2;
    
    // var account1Balance;
    // var account2Balance;
    
    
    // //  Send Dai from our constant unlocked address to any recipient
    // async function sendDai(amount, recipient){
    
    //     var amountToSend = BigInt(amount); //  1000 Dai
    
    //     console.log(`Sending  ${ amountToSend } x 10^-18 Dai to  ${recipient}`);
    
    //     await daiContract.methods.transfer(recipient,amountToSend).send({from: unlockedAddress});
    
    //     let recipientBalance = await daiContract.methods.balanceOf(recipient).call();
        
    //     console.log(`Recipient: ${recipient} DAI Balance: ${recipientBalance}`);
    
    
    // }
    
    // //  Approve a smart contract address or normal address to spend on behalf of the owner
    // async function approveDai(spender,  owner,  amount){
    
    //     await daiContract.methods.approve(spender,amount).send({from: owner});
    
    //     console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 Dai by Owner:  ${owner}`);
    
    // };
    
    // //  Approve a smart contract address or normal address to spend on behalf of the owner
    // async function approveYDai(spender,  owner,  amount){
    
    //     await yDaiContract.methods.approve(spender,amount).send({from: owner});
    
    //     console.log(`Address ${spender}  has been approved to spend ${ amount } x 10^-18 YDai by Owner:  ${owner}`);
    
    // };
    
    
    // contract('DaiLendingAdapter', () => {
    //     let daiLendingAdapterContract = null;
    //     let daiLendingServiceContract = null;
    
    //     before(async () =>{
    //         daiLendingAdapterContract = await DaiLendingAdapterContract.deployed();
    //         daiLendingServiceContract = await DaiLendingServiceContract.deployed();
    
    //         //  Get the addresses and Balances of at least 2 accounts to be used in the test
    //         //  Send DAI to the addresses
    //         web3.eth.getAccounts().then(function(accounts){
    
    //             account1 = accounts[0];
    //             account2 = accounts[1];
    
    //             //  send money from the unlocked dai address to accounts 1 and 2
    //             var amountToSend = BigInt(10000000000000000000000); //   10000 Dai
    //             sendDai(amountToSend,account1);
    //             sendDai(amountToSend,account2);                              
    
    //             //  get the eth balance of the accounts
    //             web3.eth.getBalance(account1, function(err, result) {
    //                 if (err) {
    //                     console.log(err)
    //                 } else {
            
    //                     account1Balance = web3.utils.fromWei(result, "ether");
    //                     console.log("Account 1: "+ accounts[0] + "  Balance: " + account1Balance + " ETH");
    //                 }
    //             });
        
    //             web3.eth.getBalance(account2, function(err, result) {
    //                 if (err) {
    //                     console.log(err)
    //                 } else {
    //                     account2Balance = web3.utils.fromWei(result, "ether");
    //                     console.log("Account 2: "+ accounts[1] + "  Balance: " + account2Balance + " ETH");
    //                 }
    //             });
    
    
    //         });
    //     });
    
    //     it('DaiLendingAdapter Contract: Should deploy  smart contract properly', async () => {
    //         console.log(daiLendingAdapterContract.address);
    //         assert(daiLendingAdapterContract.address !== '');
    //     });
    
    //     it('DaiLendingAdapter Contract: Should Get Current Price Per Full Share', async () => {
    
    //         var price = await daiLendingAdapterContract.GetPricePerFullShare();
    //         var value = BigInt(price);
    
    //         console.log(value);
    //         assert(value > 0);
    //     });
    
    //     it('DaiLendingAdapter Contract: Should Get Dai Balance of Accounts', async () => {
    
    //         //var balance = await daiLendingAdapterContract.GetDaiBalance(account1);
    //         var balance = await daiContract.methods.balanceOf(account1).call()
    //         var value = BigInt(balance);
    //         console.log("Dai Balance: "+value);
    //         assert(value > 0);
    //     });
    
    //     it('DaiLendingAdapter Contract: Should Get YDai Balance of Accounts', async () => {
    
    //         var balance = await daiLendingAdapterContract.GetYDaiBalance(account1);
    //         var value = BigInt(balance);
            
    //         console.log("YDai Balance: "+value);
    //         assert(value == 0);
    //     });
    // });