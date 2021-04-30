pragma solidity 0.6.6;

import "./ibDUSDLendingAdapter.sol";

contract ibDUSDLendingService {
    address _owner;
    address _delegateContract;

    ibDUSDLendingAdapter _dusdLendingAdapter;

    constructor() public {
        _owner = msg.sender;
    }

    function TransferOwnership(address account) external onlyOwner() {
        if (_owner != address(0)) _owner = account;
    }

    function UpdateAdapter(address adapterAddress) external onlyOwner() {
        _dusdLendingAdapter = ibDUSDLendingAdapter(adapterAddress);
    }

    /*
        account: this is the owner of the DUSD token
    */
    /*
        -   Before calling this function, ensure that the msg.sender or caller has given this contract address
            approval to transfer money on its behalf to another address
    */
    function Save(uint256 amount) external {
        _dusdLendingAdapter.save(amount, msg.sender);
    }

    function Withdraw(uint256 amount) external {
        _dusdLendingAdapter.Withdraw(amount, msg.sender);
    }

    function WithdrawByShares(uint256 amount, uint256 sharesAmount) external {
        _dusdLendingAdapter.WithdrawByShares(amount, msg.sender, sharesAmount);
    }

    function WithdrawBySharesOnly(uint256 sharesAmount) external {
        _dusdLendingAdapter.WithdrawBySharesOnly(msg.sender, sharesAmount);
    }

    function UserBUSDBalance(address user) external view returns (uint256) {
        return _dusdLendingAdapter.GetBUSDBalance(user);
    }

    function UserShares(address user) external view returns (uint256) {
        return _dusdLendingAdapter.GetIBDUSDBalance(user);
    }

    function GetDUSDLendingAdapterAddress() external view returns (address) {
        return address(_dusdLendingAdapter);
    }
    function GetPricePerFullShare() external view returns (uint){
        
        return _dusdLendingAdapter.GetPricePerFullShare();
    }

      modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can make this call");
        _;
    }
}
