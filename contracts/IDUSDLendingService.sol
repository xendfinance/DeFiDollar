pragma solidity 0.6.6;


interface IDUSDLendingService {

    function Save(uint256 amount) external;
    
    function Withdraw(uint256 amount) external;

    function WithdrawByShares(uint256 amount, uint256 sharesAmount) external;

    function WithdrawBySharesOnly(uint256 sharesAmount) external;

    function GetDUSDLendingAdapterAddress() external view returns (address);

    function UserShares(address user) external view returns (uint256);

    function UserDUSDBalance(address user) external view returns (uint256);


}