
pragma solidity 0.6.6;
import "./ISavingsConfig.sol";
import "./ITreasury.sol";
// import "./Ownable.sol";
import "./IGroups.sol";
import "./SafeERC20.sol";

import "./ICycle.sol";
import "./IGroupSchema.sol";
import "./ibDUSDLendingService.sol";
import "./IERC20.sol";
import "./IibDUSD.sol";
//import "./Address.sol";
import "./IRewardConfig.sol";
import "./SafeMath.sol";
import "./IXendFinanceGroup_Yearn_V1Helpers.sol";

pragma experimental ABIEncoderV2;


contract XendFinanceGroup_Yearn_V1Helpers is IXendFinanceGroup_Yearn_V1Helpers
{
    using SafeMath for uint256;
    IGroups groupStorage;
    ICycles cycleStorage;

     constructor(      
        address groupStorageAddress,
        address cycleStorageAddress       
    ) public {       
        groupStorage = IGroups(groupStorageAddress);
        cycleStorage = ICycles(cycleStorageAddress);      
    }

        
    function getCycleMemberByIndex(uint256 index)
        external 
        override
        view
        returns (CycleMember memory)
    {
        (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        ) = cycleStorage.getCycleMember(index);

        return
            CycleMember(
                true,
                cycleId,
                groupId,
                _address,
                totalLiquidityAsPenalty,
                numberOfCycleStakes,
                stakesClaimed,
                hasWithdrawn
            );
    }


    function getCycleMemberByCycleId(
        uint256 _cycleId,
        uint256 indexerRecordLocation
    )
        external
        override
        view
        returns (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        )
    {
        (bool exists, uint256 index) =
            cycleStorage.getRecordIndexForCycleMembersIndexerByDepositor(
                _cycleId,
                indexerRecordLocation
            );
        require(exists == true, "Index location record does not exist");
        return cycleStorage.getCycleMember(index);
    }

    function getCycleByGroup(uint256 _groupId, uint256 indexerRecordLocation)
        external
        override
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
        )
    {
        uint256 index = _getIndexLocation(_groupId, indexerRecordLocation);
        return cycleStorage.getCycleInfoByIndex(index);
    }

    function _getIndexLocation(uint256 _groupId, uint256 indexerRecordLocation)
        internal
        view
        returns (uint256)
    {
        (bool exists, uint256 index) =
            cycleStorage.getRecordIndexForGroupCycle(
                _groupId,
                indexerRecordLocation
            );
        require(exists == true, "Index location record does not exist");
        return index;
    }

    function getGroupsByCreator(
        address groupCreator,
        uint256 indexRecordPosition
    )
        external
        override
        view
        returns (
            uint256 groupId,
            string memory name,
            string memory symbol,
            address payable creatorAddress
        )
    {
        (bool exists, uint256 index) =
            groupStorage.getGroupForCreatorIndexer(
                groupCreator,
                indexRecordPosition
            );
        require(exists == true, "Index record location does not exist");
        return groupStorage.getGroupByIndex(index);
    }

    function _getGroupById(uint256 _groupId)
        internal
        view
        returns (Group memory)
    {
        (
            uint256 groupId,
            string memory name,
            string memory symbol,
            address payable creatorAddress
        ) = groupStorage.getGroupById(_groupId);

        Group memory group = Group(true, groupId, name, symbol, creatorAddress);
        return group;
    }
  
  

    function getGroup(uint256 groupId) external override view returns (Group memory) {
        return _getGroupById(groupId);
    }

   



    function validateCycleCreationActionValid(
        uint256 groupId,
        uint256 maximumsSlots,
        bool hasMaximumSlots
    ) external override view {
        bool doesGroupExist = groupStorage.doesGroupExist(groupId);

        require(doesGroupExist == true, "Group not found");

        if (hasMaximumSlots == true) {
            require(maximumsSlots > 0, "Maximum slot settings cannot be empty");
        }
    }

      function getCycleGroup(uint256 cycleId)
        external
        override
        view
        returns (Group memory)
    {
        Cycle memory cycle = _getCycleById(cycleId);

        return _getGroupById(cycle.groupId);
    }

  
     function getCycleById(uint256 cycleId)
        external
        override
        view
        returns (Cycle memory)
    {
       return _getCycleById(cycleId);
    }

    function _getCycleById(uint256 cycleId)
        internal
        view
        returns (Cycle memory)
    {
        (
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
        ) = cycleStorage.getCycleInfoById(cycleId);

        Cycle memory cycleInfo =
            Cycle(
                true,
                id,
                groupId,
                numberOfDepositors,
                cycleStartTimeStamp,
                cycleDuration,
                maximumSlots,
                hasMaximumSlots,
                cycleStakeAmount,
                totalStakes,
                stakesClaimed,
                cycleStatus,
                stakesClaimedBeforeMaturity
            );

        return cycleInfo;
    }

    function getCycleFinancialByCycleId(uint256 cycleId)
        external
        override
        view
        returns (CycleFinancial memory)
    {
        return _getCycleFinancialByCycleId(cycleId);
    }

    function _getCycleFinancialByCycleId(uint256 cycleId)
        internal
        view
        returns (CycleFinancial memory)
    {
        (
            uint256 underlyingTotalDeposits,
            uint256 underlyingTotalWithdrawn,
            uint256 underlyingBalance,
            uint256 derivativeBalance,
            uint256 underylingBalanceClaimedBeforeMaturity,
            uint256 derivativeBalanceClaimedBeforeMaturity
        ) = cycleStorage.getCycleFinancialsByCycleId(cycleId);

        return
            CycleFinancial(
                true,
                cycleId,
                underlyingTotalDeposits,
                underlyingTotalWithdrawn,
                underlyingBalance,
                derivativeBalance,
                underylingBalanceClaimedBeforeMaturity,
                derivativeBalanceClaimedBeforeMaturity
            );
    }

      function getCycleMemberIndex(
        uint256 cycleId,
        address payable memberAddress
    ) external override view returns (uint256) {
        return _getCycleMemberIndex(cycleId, memberAddress);
    }

    function _getCycleMemberIndex(
        uint256 cycleId,
        address payable memberAddress
    ) internal view returns (uint256) {
        return cycleStorage.getCycleMemberIndex(cycleId, memberAddress);
    }

    function getCycleMemberByAddressAndCycleId(address payable depositor, uint256 _cycleId)
        external 
        override
        view
        returns (CycleMember memory)
    {
       return _getCycleMember(depositor,_cycleId);
    }


    function _getCycleMember(address payable depositor, uint256 _cycleId)
        internal
        view
        returns (CycleMember memory)
    {
        bool cycleMemberExists =
            cycleStorage.doesCycleMemberExist(_cycleId, depositor);

        require(cycleMemberExists == true, "Cycle Member not found");

        uint256 index = _getCycleMemberIndex(_cycleId, depositor);

        CycleMember memory cycleMember = _getCycleMember(index);
        return cycleMember;
    }

  

    function getCycleMember(address payable _depositorAddress, uint256 _cycleId)
        external
        override
        view
        returns (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        )
    {
        CycleMember memory cycleMember =
            _getCycleMember(_depositorAddress, _cycleId);
        return (
            cycleMember.cycleId,
            cycleMember.groupId,
            cycleMember._address,
            cycleMember.totalLiquidityAsPenalty,
            cycleMember.numberOfCycleStakes,
            cycleMember.stakesClaimed,
            cycleMember.hasWithdrawn
        );
    }

    function getCycleMember(uint256 index)
        external
        override
        view
        returns (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        )
    {
        return cycleStorage.getCycleMember(index);
    }

    function _getCycleMember(uint256 index)
        internal
        view
        returns (CycleMember memory)
    {
        (
            uint256 cycleId,
            uint256 groupId,
            address payable _address,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        ) = cycleStorage.getCycleMember(index);

        return
            CycleMember(
                true,
                cycleId,
                groupId,
                _address,
                totalLiquidityAsPenalty,
                numberOfCycleStakes,
                stakesClaimed,
                hasWithdrawn
            );
    }

    
   

   

  

     function getDerivativeAmountForUserStake(
        uint256 cycleId,
        address payable memberAddress
    ) external override view returns (uint256) {
        Cycle memory cycle = _getCycleById(cycleId);
        CycleFinancial memory cycleFinancial =
            _getCycleFinancialByCycleId(cycleId);
        bool memberExistInCycle =
            cycleStorage.doesCycleMemberExist(cycleId, memberAddress);

        require(
            memberExistInCycle == true,
            "You are not a member of this cycle"
        );

        uint256 index = _getCycleMemberIndex(cycle.id, memberAddress);

        CycleMember memory cycleMember = _getCycleMember(index);

        uint256 numberOfStakesByMember = cycleMember.numberOfCycleStakes;

        // get's the worth of one stake of the cycle in the derivative amount e.g yDAI
        uint256 derivativeAmountForStake =
            cycleFinancial.derivativeBalance.div(cycle.totalStakes);

        //get's how much of a crypto asset the user has deposited. e.g yDAI
        uint256 derivativeBalanceForMember =
            derivativeAmountForStake.mul(numberOfStakesByMember);
        return derivativeBalanceForMember;
    }

      function getGroupCreator(uint256 groupId) external override returns (address) {
        Group memory group = _getGroupById(groupId);

        address groupCreator = group.creatorAddress;

        return groupCreator;
    }

      function validateGroupNameAndSymbolIsAvailable(
        string calldata name,
        string calldata symbol
    ) external override view {
        bytes memory nameInBytes = bytes(name); // Uses memory
        bytes memory symbolInBytes = bytes(symbol); // Uses memory

        require(nameInBytes.length > 0, "Group name cannot be empty");
        require(symbolInBytes.length > 0, "Group sysmbol cannot be empty");

        bool nameExist = groupStorage.doesGroupExist(name);

        require(nameExist == false, "Group name has already been used");
    }

    // function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
    //         uint number = _i;
    //         if (number == 0) {
    //             return "0";
    //         }
    //         uint j = number;
    //         uint len;
    //         while (j != 0) {
    //             len++;
    //             j /= 10;
    //         }
    //         bytes memory bstr = new bytes(len);
    //         uint k = len - 1;
    //         while (number != 0) {
    //             bstr[k--] = byte(uint8(48 + number % 10));
    //             number /= 10;
    //         }
    //         return string(bstr);
    //     }

   

    function getAmountToBillClient(uint256 cycleId, uint256 numberOfStakes)
        external
        override
        view
        returns (uint256)
    {
        Cycle memory cycle = _getCycleById(cycleId);

        uint256 amountToDeductFromClient =
            cycle.cycleStakeAmount.mul(numberOfStakes);
        return amountToDeductFromClient;
    }

    function validateCycleDepositCriteriaAreMet(
        bool hasMaximumSlots,
        CycleStatus cycleStatus,
        uint numberOfDepositors,
        uint maximumSlots,
        bool didCycleMemberExistBeforeNow
    ) external override view {
        bool hasMaximumSlots = hasMaximumSlots;
        if (hasMaximumSlots == true && didCycleMemberExistBeforeNow == false) {
            require(
                numberOfDepositors < maximumSlots,
                "Maximum slot for depositors has been reached"
            );
        }

        require(
            cycleStatus == CycleStatus.NOT_STARTED,
            "This cycle is not accepting deposits anymore"
        );
    }

  

    

    // function _processMemberDeposit(
    //     uint256 numberOfStakes,
    //     uint256 amountForStake,
    //     address payable depositorAddress
    // ) internal returns (uint256 underlyingAmount) {
    //     uint256 expectedAmount = numberOfStakes.mul(amountForStake);

    //     address recipient = address(this);
    //     uint256 amountTransferrable = stakedToken.allowance(
    //         depositorAddress,
    //         recipient
    //     );

    //     require(
    //         amountTransferrable > 0,
    //         "Approve an amount > 0 for token before proceeding"
    //     );
    //     require(
    //         amountTransferrable >= expectedAmount,
    //         "Token allowance does not cover stake claim"
    //     );

    //     bool isSuccessful = stakedToken.transferFrom(
    //         depositorAddress,
    //         recipient,
    //         expectedAmount
    //     );
    //     require(
    //         isSuccessful == true,
    //         "Could not complete deposit process from token contract"
    //     );

    //     return expectedAmount;
    // }

    

    function isCycleReadyToBeEnded(uint256 cycleId)
        external
        override
        view
        returns (bool)
    {
        Cycle memory cycle = _getCycleById(cycleId);

        if (cycle.cycleStatus != CycleStatus.ONGOING) return false;

        uint256 currentTimeStamp = now;
        uint256 cycleEndTimeStamp =
            cycle.cycleStartTimeStamp + cycle.cycleDuration;

        if (currentTimeStamp >= cycleEndTimeStamp) return true;
        else return false;
    }   

    function getCycleEndCheckResult(uint256 cycleId) external view returns(uint256,uint256,uint256,uint256,CycleStatus,bool) {
        Cycle memory cycle = _getCycleById(cycleId);
         uint256 cycleEndTimeStamp =
            cycle.cycleStartTimeStamp + cycle.cycleDuration;
         uint256 currentTimeStamp = now;

        return (currentTimeStamp,cycle.cycleDuration,cycle.cycleStartTimeStamp, cycleEndTimeStamp,cycle.cycleStatus,currentTimeStamp >= cycleEndTimeStamp);
    }
}

