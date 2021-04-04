pragma solidity 0.6.6;

import "./IibDUSD.sol";
import "./SafeMath.sol";
import "./OwnableService.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";



contract ibDUSDLendingAdapter is OwnableService, ReentrancyGuard{
    
    using SafeMath for uint256;

    using SafeERC20 for IibDUSD;

    using SafeERC20 for IERC20;

    IibDUSD _ibDusd;

    IERC20 _dusd;

     constructor(address payable serviceContract) public OwnableService(serviceContract){

         // https://github.com/defidollar/defidollar-core/tree/master/contracts/stream

        _ibDusd = IibDUSD(0x42600c4f6d84Aa4D246a3957994da411FA8A4E1c); // interest-bearing DUSD ( shares ) smart contract address Main Network
        _dusd = IERC20(0x5BC25f649fc4e26069dDF4cF4010F9f706c23831); // DUSD address Main Network
        
    }

    mapping(address => uint256) userDUSDDeposits;

    function GetPricePerFullShare() external view returns (uint256){
        
        return _ibDusd.getPricePerFullShare();
    }
 
    /**
        Get the DUSD balance of the interest-bearing DUSD smart contract
    */
    function GetIBDUSDContractBalance() external view returns (uint256){
        return _ibDusd.balance();
    }
    
    
    function GetDUSDBalance(address account) external view returns (uint256){
        return _dusd.balanceOf(account);
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
        _dusd.safeTransferFrom(account, address(this), amount);

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

        uint256 userDUSDDepositBalance = userDUSDDeposits[account].mul(1e18); // multiply dai deposit by 1 * 10 ^ 18 to get value in 10 ^36

        return grossBalance.sub(userDUSDDepositBalance);
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
        uint256 balanceDUSD = _dusd.balanceOf(address(this));

        if (balanceDUSD > 0) {
            //  This gives the _ibDusd contract approval to invest our DUSD
            _save(balanceDUSD, owner);
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
        uint256 balanceDUSD = _dusd.balanceOf(address(this));

        if (balanceDUSD > 0) {
            //  This gives the yDAI contract approval to invest our DAI
            _save(balanceDUSD, owner);
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
        //  Approve the IBDUSD contract address to spend amount of DUSD
        _dusd.approve(address(_ibDusd), amount);

        //  Now our yDAI contract has deposited our DAI and it is earning interest and this gives us yDAI token in this Wallet contract
        //  and we will use the yDAI token to redeem our DAI
        _ibDusd.deposit(amount);

        //  call balanceOf and get the total balance of ibDusd shares in this contract
        uint256 shares = _ibDusd.balanceOf(address(this));

        //  transfer the _ibDusd shares to the user's address
        _ibDusd.safeTransfer(account, shares);

        //  add deposited dai to userDaiDeposits mapping
        userDUSDDeposits[account] = userDUSDDeposits[account].add(amount);
    }
    
    function _withdrawBySharesOnly(address owner, uint256 balanceShares) internal {

        //  We now call the withdraw function to withdraw the total DUSD we have. This withdrawal is sent to this smart contract
        _ibDusd.withdraw(balanceShares);

        uint256 contractDUSDBalance = _dusd.balanceOf(address(this));

        //  Now all the DAI we have are in the smart contract wallet, we can now transfer the total amount to the recipient
        _dusd.safeTransfer(owner, contractDUSDBalance);

        //   remove withdrawn dai of this owner from userDaiDeposits mapping
        if (userDUSDDeposits[owner] >= contractDUSDBalance) {
            userDUSDDeposits[owner] = userDUSDDeposits[owner].sub(
                contractDUSDBalance
            );
        } else {
            userDUSDDeposits[owner] = 0;
        }
    }
    
    function _withdrawBySharesAndAmount(address owner, uint256 balanceShares, uint256 amount) internal {
        
        //  We now call the withdraw function to withdraw the total DUSD we have. This withdrawal is sent to this smart contract
        _ibDusd.withdraw(balanceShares);

        //  Now all the DUSD we have are in the smart contract wallet, we can now transfer the specified amount to a recipient of our choice
        _dusd.safeTransfer(owner, amount);
        

        //   remove withdrawn DUSD of this owner from userDaiDeposits mapping
        if (userDUSDDeposits[owner] >= amount) {
            userDUSDDeposits[owner] = userDUSDDeposits[owner].sub(
                amount
            );
        } else {
            userDUSDDeposits[owner] = 0;
        }
    }
}