// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;
import "./ISavingsConfig.sol";
import "./ITreasury.sol";
// import "./Ownable.sol";
import "./IGroups.sol";
import "./SafeERC20.sol";

import "./ICycle.sol";
import "./IGroupSchema.sol";
import "./IDUSDLendingService.sol";
import "./IERC20.sol";
import "./IibDUSD.sol";
//import "./Address.sol";
import "./IRewardConfig.sol";
import "./SafeMath.sol";
import "./IRewardBridge.sol";
import "./IXendFinanceGroup_Yearn_V1Helpers.sol";


contract XendFinanceGroupContainer_Yearn_V1 is IGroupSchema {
    struct CycleDepositResult {
        Group group;
        Member member;
        GroupMember groupMember;
        CycleMember cycleMember;
        uint256 underlyingAmountDeposited;
    }

    struct WithdrawalResolution {
        uint256 amountToSendToMember;
        uint256 amountToSendToTreasury;
    }
    event GroupCreated(
        uint256 indexed groupId,
        address payable indexed groupCreator
    );

    event CycleCreated(
        uint256 indexed cycleId,
        uint256 maximumSlots,
        bool hasMaximumSlots,
        uint256 stakeAmount,
        uint256 expectedCycleStartTimeStamp,
        uint256 cycleDuration
    );

    event CycleStarted(uint256 indexed cycleId, uint256 cycleStartTimeStamp);

    event UnderlyingAssetDeposited(
        uint256 indexed cycleId,
        address payable indexed memberAddress,
        uint256 groupId,
        uint256 underlyingAmount,
        address indexed tokenAddress
    );

    event XendTokenReward(
        uint256 date,
        address payable indexed member,
        uint256 amount
    );

    IDUSDLendingService daiLendingService;
    IERC20 stakedToken;
    IGroups groupStorage;
    ICycles cycleStorage;
    ITreasury treasury;
    ISavingsConfig savingsConfig;
    IRewardConfig rewardConfig;
    IRewardBridge rewardBridge;
    IibDUSD derivativeToken;
    IXendFinanceGroup_Yearn_V1Helpers xendFinanceGroupHelpers;

    address TokenAddress;
    address TreasuryAddress;

    string constant PERCENTAGE_PAYOUT_TO_USERS = "PERCENTAGE_PAYOUT_TO_USERS";
    string constant PERCENTAGE_AS_PENALTY = "PERCENTAGE_AS_PENALTY";
    
    string constant XEND_FINANCE_COMMISION_DIVIDEND =
        "XEND_FINANCE_COMMISION_DIVIDEND";

    string XEND_FEE_PRECISION = "XEND_FEE_PRECISION";

    bool isDeprecated = false;

    uint256 _groupCreatorRewardPercent;

    uint256 _totalTokenReward; //  This tracks the total number of token rewards distributed on the individual savings

    modifier onlyNonDeprecatedCalls() {
        require(isDeprecated == false, "Service contract has been deprecated");
        _;
    }
}