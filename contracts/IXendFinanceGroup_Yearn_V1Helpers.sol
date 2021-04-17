
pragma solidity 0.6.6;
import "./IGroupSchema.sol";
pragma experimental ABIEncoderV2;


interface IXendFinanceGroup_Yearn_V1Helpers   is IGroupSchema 
{
    function getCycleMemberByAddressAndCycleId(address payable depositor, uint256 _cycleId)
        external 
        view
        returns (CycleMember memory);

      function getCycleMemberByIndex(uint256 index)
        external 
        view
        returns (CycleMember memory);

     function getCycleMemberIndex(
        uint256 cycleId,
        address payable memberAddress
    ) external view returns (uint256);
   
       function getCycleMemberByCycleId(
        uint256 _cycleId,
        uint256 indexerRecordLocation
    )
        external
        view
        returns (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        );

    function getCycleByGroup(uint256 _groupId, uint256 indexerRecordLocation)
        external
        view
        returns (
            uint256 id,
            uint256 groupId,
            uint256 numberOfDepositors,
            uint256 cycleStartTimeStamp,
            uint256 cycleDuration,
            uint256 maximumSlots,
            bool hasMaximumSlots,
            uint256 cycleStakeAmount,
            uint256 totalStakes,
            uint256 stakesClaimed,
            CycleStatus cycleStatus,
            uint256 stakesClaimedBeforeMaturity
        );

    function getGroupsByCreator(
        address groupCreator,
        uint256 indexRecordPosition
    )
        external
        view
        returns (
            uint256 groupId,
            string memory name,
            string memory symbol,
            address payable creatorAddress
        );
  
   

    function getGroup(uint256 groupId) external view returns (Group memory) ;

   



    function validateCycleCreationActionValid(
        uint256 groupId,
        uint256 maximumsSlots,
        bool hasMaximumSlots
    ) external view ;

      function getCycleGroup(uint256 cycleId)
        external
        view
        returns (Group memory);

  
     function getCycleById(uint256 cycleId)
        external
        view
        returns (Cycle memory);

  

    function getCycleFinancialByCycleId(uint256 cycleId)
        external
        view
        returns (CycleFinancial memory);

  

    function getCycleMember(address payable _depositorAddress, uint256 _cycleId)
        external
        view
        returns (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        );

    function getCycleMember(uint256 index)
        external
        view
        returns (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        );

    function getDerivativeAmountForUserStake(
        uint256 cycleId,
        address payable memberAddress
    ) external view returns (uint256);

      function getGroupCreator(uint256 groupId) external returns (address) ;

      function validateGroupNameAndSymbolIsAvailable(
        string calldata name,
        string calldata symbol
    ) external view ;

    function getAmountToBillClient(uint256 cycleId, uint256 numberOfStakes)
        external
        view
        returns (uint256);

    function validateCycleDepositCriteriaAreMet(
        bool hasMaximumSlots,
        CycleStatus cycleStatus,
        uint numberOfDepositors,
        uint maximumSlots,
        bool didCycleMemberExistBeforeNow
    ) external view ;
    

    function isCycleReadyToBeEnded(uint256 cycleId)
        external
        view
        returns (bool);

}

