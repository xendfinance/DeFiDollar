pragma solidity 0.6.6;

interface IZap {
    function deposit(uint[] calldata inAmounts, uint minDusdAmount) external returns (uint dusdAmount);
    
    function withdraw(uint shares, uint8 i, uint minOut) external returns (uint);

}