pragma solidity 0.6.6;

import './IERC20.sol';

/*
    This interface is for the interest-bearing DUSD contract
*/



interface IibDUSD is IERC20{
    
    function deposit(uint _amount) external;
    function withdraw(uint _shares) external;
    function balance() external view returns (uint);
    function getPricePerFullShare() external view returns (uint);
}