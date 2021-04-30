pragma solidity 0.6.6;

import "./IibDUSD.sol";
import "./SafeMath.sol";
import "./OwnableService.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IZap.sol";


contract ibDUSDLendingAdapter is OwnableService, ReentrancyGuard{
    
    using SafeMath for uint256;

    using SafeERC20 for IibDUSD;

    using SafeERC20 for IERC20;

    IibDUSD _ibDusd;

    IERC20 _busd;

    IZap _zap;

    uint8 BUSD_COIN_INDEX = 0;
    uint8 USDT_COIN_INDEX = 1;
    uint8 USDC_COIN_INDEX = 2;

     constructor(address payable serviceContract) public OwnableService(serviceContract){

         // https://github.com/defidollar/defidollar-core/tree/master/contracts/stream
         // https://github.com/defidollar/defidollar-bsc/blob/main/deployments/mainnet.json


        _ibDusd = IibDUSD(0x4EaC4c4e9050464067D673102F8E24b2FccEB350); // interest-bearing DUSD ( shares ) smart contract address Main Network
        _busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD on Binance Smart Chain
        _zap = IZap(0x90c52436C9e52DC3E33082a32c0F19225a9F38AB); //         

    }

    
    mapping(address => uint256) userBUSDDeposits;

    function GetPricePerFullShare() external view returns (uint256){
        
        return _ibDusd.getPricePerFullShare();
    }
 
    /**
        Get the DUSD balance of the interest-bearing DUSD smart contract
    */
    function GetIBDUSDContractBalance() external view returns (uint256){
        return _ibDusd.balance();
    }
    
    
    function GetBUSDBalance(address account) external view returns (uint256){
        return _busd.balanceOf(account);
    }


    function GetIBDUSDBalance(address account) public view returns (uint256) {
        return _ibDusd.balanceOf(account);
    }

    /*
        account: this is the owner of the DUSD token
    */
    function save(uint256 amount, address account)
        public
        nonReentrant
        onlyOwnerAndServiceContract
    {
        //  Give allowance that a spender can spend on behalf of the owner. NOTE: This approve function has to be called from outside this smart contract because if you call
        //  it from the smart contract, it will use the smart contract address as msg.sender which is not what we want,
        //  we want the address with the DAI token to be the one that will be msg.sender. Hence the line below will not work and needs to be called
        //  from Javascript or C# environment
        //   dai.approve(address(this),amount); (Not work)

        //  See example with Node.js below
        //  await daiContract.methods.approve("recipient(in our case, this smart contract address)",1000000).send({from: "wallet address with DAI"});

        //  Transfer DAI from the account address to this smart contract address
        _busd.safeTransferFrom(account, address(this), amount);

        //  This gives the yDAI contract approval to invest our DAI
        _save(amount, account);
    }

    //  This function returns your DAI balance + interest. NOTE: There is no function in Yearn finance that gives you the direct balance of DAI
    //  So you have to get it in two steps

    function GetGrossRevenue(address account) public view returns (uint256) {
        //  Get the price per full share
        uint256 price = _ibDusd.getPricePerFullShare();

        //  Get the balance of yDai in this users address
        uint256 balanceShares = _ibDusd.balanceOf(account);

        return balanceShares.mul(price);
    }

    function GetNetRevenue(address account) public view returns (uint256) {
        uint256 grossBalance = GetGrossRevenue(account);

        uint256 userBUSDDepositBalance = userBUSDDeposits[account].mul(1e18); // multiply dai deposit by 1 * 10 ^ 18 to get value in 10 ^36

        return grossBalance.sub(userBUSDDepositBalance);
    }

    function Withdraw(uint256 amount, address owner)
        public
        nonReentrant
        onlyOwnerAndServiceContract
    {
        //  To withdraw our DUSD amount, the amount argument is in DUSD but the withdraw function of the IBDUSD expects amount in IBDUSD
        //  So we need to find our balance in IBDUSD

        uint256 balanceShares = _ibDusd.balanceOf(owner);

        //  transfer ibDusd shares From owner to this contract address
        _ibDusd.safeTransferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DUSD we have. This withdrawal is sent to this smart contract
        _withdrawBySharesAndAmount(owner,balanceShares,amount);

        //  If we have some DUSD left after transferring a specified amount to a recipient, we can re-invest it in yearn finance
        uint256 balanceBUSD = _busd.balanceOf(address(this));

        if (balanceBUSD > 0) {
            //  This gives the _ibDusd contract approval to invest our DUSD
            _save(balanceBUSD, owner);
        }
    }

    function WithdrawByShares(
        uint256 amount,
        address owner,
        uint256 sharesAmount
    ) public
    nonReentrant
    onlyOwnerAndServiceContract
    {
           //  To withdraw our DAI amount, the amount argument is in DAI but the withdraw function of the yDAI expects amount in yDAI token

        uint256 balanceShares = sharesAmount;

        //  transfer _ibDusd From owner to this contract address
        _ibDusd.safeTransferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DUSD we have. This withdrawal is sent to this smart contract
        _withdrawBySharesAndAmount(owner,balanceShares,amount);

        //  If we have some DAI left after transferring a specified amount to a recipient, we can re-invest it in yearn finance
        uint256 balanceBUSD = _busd.balanceOf(address(this));

        if (balanceBUSD > 0) {
            //  This gives the yDAI contract approval to invest our DAI
            _save(balanceBUSD, owner);
        }
    }

    /*
        this function withdraws all the dai to this contract based on the sharesAmount passed
    */
    function WithdrawBySharesOnly(address owner, uint256 sharesAmount)
        public
        nonReentrant
        onlyOwnerAndServiceContract
    {
        uint256 balanceShares = sharesAmount;

        //  transfer _ibDusd shares From owner to this contract address
        _ibDusd.safeTransferFrom(owner, address(this), balanceShares);

        //  We now call the withdraw function to withdraw the total DAI we have. This withdrawal is sent to this smart contract
        _withdrawBySharesOnly(owner,balanceShares);

    }

    //  This function is an internal function that enabled DAI contract where user has money to approve the yDai contract address to invest the user's DAI
    //  and to send the yDai shares to the user's address
    function _save(uint256 amount, address account) internal {

        // BUSD is expected, so Zap into dusd and deposit

        //  Amounts assets supported in Zap -> BUSD/USDT/USDC
         uint256[] memory inAmounts = new uint[](3);
         inAmounts[BUSD_COIN_INDEX] = uint256(amount);
         inAmounts[USDT_COIN_INDEX] = uint256(0);
         inAmounts[USDC_COIN_INDEX] = uint256(0);

        //  approve zap contract to spend the BUSD
        _busd.approve(address(_zap),amount);

        // perform zap from BUSD to DUSD
        uint256 dusdAmount = _zap.deposit(inAmounts,0);

        //  call balanceOf and get the total balance of ibDusd shares in this contract
        uint256 shares = _ibDusd.balanceOf(address(this));

        //  transfer the _ibDusd shares to the user's address
        _ibDusd.safeTransfer(account, shares);

        //  add deposited dai to userDaiDeposits mapping
        userBUSDDeposits[account] = userBUSDDeposits[account].add(amount);
    }
    
    function _withdrawBySharesOnly(address owner, uint256 balanceShares) internal {

        //  Give Zap contract permission to transfer shares
        _ibDusd.approve(address(_zap),balanceShares);

        //  We now call the withdraw function on Zap to withdraw the total BUSD we have. This withdrawal is sent to this smart contract
        _zap.withdraw(balanceShares,BUSD_COIN_INDEX,0);

        uint256 contractBUSDBalance = _busd.balanceOf(address(this));

        //  Now all the DAI we have are in the smart contract wallet, we can now transfer the total amount to the recipient
        _busd.safeTransfer(owner, contractBUSDBalance);

        //   remove withdrawn dai of this owner from userDaiDeposits mapping
        if (userBUSDDeposits[owner] >= contractBUSDBalance) {
            userBUSDDeposits[owner] = userBUSDDeposits[owner].sub(
                contractBUSDBalance
            );
        } else {
            userBUSDDeposits[owner] = 0;
        }
    }
    
    function _withdrawBySharesAndAmount(address owner, uint256 balanceShares, uint256 amount) internal {
        
        //  Give Zap contract permission to transfer shares
        _ibDusd.approve(address(_zap),balanceShares);

        //  We now call the withdraw function on Zap to withdraw the total BUSD we have. This withdrawal is sent to this smart contract
        _zap.withdraw(balanceShares,BUSD_COIN_INDEX,0);

        //  Now all the DUSD we have are in the smart contract wallet, we can now transfer the specified amount to a recipient of our choice
        _busd.safeTransfer(owner, amount);
        

        //   remove withdrawn DUSD of this owner from userDaiDeposits mapping
        if (userBUSDDeposits[owner] >= amount) {
            userBUSDDeposits[owner] = userBUSDDeposits[owner].sub(
                amount
            );
        } else {
            userBUSDDeposits[owner] = 0;
        }
    }
}