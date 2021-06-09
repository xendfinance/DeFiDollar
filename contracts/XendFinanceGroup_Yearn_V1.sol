pragma solidity 0.6.6;
import "./ISavingsConfig.sol";
import "./ITreasury.sol";
import "./Ownable.sol";
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
import "./XendFinanceGroupContainer_Yearn_V1.sol";
import "./IXendFinanceGroup_Yearn_V1Helpers.sol";
pragma experimental ABIEncoderV2;


contract XendFinanceGroup_Yearn_V1 is
    XendFinanceGroupContainer_Yearn_V1,
    ISavingsConfigSchema,
    Ownable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IibDUSD;

    using Address for address payable;
    using Address for address;
    constructor(
        address lendingServiceAddress,
        address tokenAddress,
        address groupStorageAddress,
        address cycleStorageAddress,
        address treasuryAddress,
        address savingsConfigAddress,
        address rewardConfigAddress,
        address rewardBridgeAddress,
        address derivativeTokenAddress,
        address xendFinanceGroupHelpersAddress
    ) public {
        daiLendingService = IDUSDLendingService(lendingServiceAddress);
        stakedToken = IERC20(tokenAddress);
        groupStorage = IGroups(groupStorageAddress);
        cycleStorage = ICycles(cycleStorageAddress);
        treasury = ITreasury(treasuryAddress);
        savingsConfig = ISavingsConfig(savingsConfigAddress);
        rewardConfig = IRewardConfig(rewardConfigAddress);
        rewardBridge = IRewardBridge(rewardBridgeAddress);
        derivativeToken = IibDUSD(derivativeTokenAddress);
        TokenAddress = tokenAddress;
        TreasuryAddress = treasuryAddress;
        xendFinanceGroupHelpers = IXendFinanceGroup_Yearn_V1Helpers(xendFinanceGroupHelpersAddress);


    }

    function GetTotalTokenRewardDistributed() external view returns (uint256) {
        return _totalTokenReward;
    }

    function setGroupCreatorRewardPercent(uint256 percent) external onlyOwner {
        _groupCreatorRewardPercent = percent;
    }

   
    function setXendFinanceGroupHelpersAddress(address xendFinanceGroupHelpersAddress) external onlyOwner {
        xendFinanceGroupHelpers = IXendFinanceGroup_Yearn_V1Helpers(xendFinanceGroupHelpersAddress);
    }

     function getXendFinanceGroupHelpersAddress() external view returns (address) {
        return address(xendFinanceGroupHelpers);
    }

    function withdrawFromCycleWhileItIsOngoing(uint256 cycleId)
        external
        onlyNonDeprecatedCalls
    {
        address payable memberAddress = msg.sender;
        _withdrawFromCycleWhileItIsOngoing(cycleId, memberAddress);
    }

      function _createMemberIfNotExist(address payable depositor)
        internal
        returns (Member memory)
    {
        Member memory member = _getMember(depositor, false);
        return member;
    }

    function _joinCycle(
        uint256 cycleId,
        uint256 numberOfStakes,
        uint256 allowance,
        address payable depositorAddress
    ) internal {
        require(numberOfStakes > 0, "Minimum stakes that can be acquired is 1");

        Group memory group = xendFinanceGroupHelpers.getCycleGroup(cycleId);
        Cycle memory cycle = xendFinanceGroupHelpers.getCycleById(cycleId); 
        CycleFinancial memory cycleFinancial = xendFinanceGroupHelpers.getCycleFinancialByCycleId(cycleId);

        bool didCycleMemberExistBeforeNow =
            cycleStorage.doesCycleMemberExist(cycleId, depositorAddress);

        bool didGroupMemberExistBeforeNow =
            groupStorage.doesGroupMemberExist(group.id, depositorAddress);
       
        xendFinanceGroupHelpers.validateCycleDepositCriteriaAreMet(cycle.hasMaximumSlots, cycle.cycleStatus, cycle.numberOfDepositors, cycle.maximumSlots, didCycleMemberExistBeforeNow);

        uint256 amountToDeductFromClient =
            cycle.cycleStakeAmount.mul(numberOfStakes);

        CycleDepositResult memory result =
            _addDepositorToCycle(
                cycleId,
                cycle.cycleStakeAmount,
                numberOfStakes,
                amountToDeductFromClient,
                depositorAddress
            );

        uint256 derivativeAmount =
            _lendCycleDeposit(allowance, amountToDeductFromClient);

        cycle = _updateCycleStakeDeposit(cycle, cycleFinancial, numberOfStakes);

        cycleFinancial.derivativeBalance = cycleFinancial.derivativeBalance.add(
            derivativeAmount
        );

        _updateCycleFinancials(cycleFinancial);

        emit UnderlyingAssetDeposited(
            cycle.id,
            depositorAddress,
            result.group.id,
            result.underlyingAmountDeposited,
            TokenAddress
        );

        if (!didCycleMemberExistBeforeNow) {
            cycle.numberOfDepositors = cycle.numberOfDepositors.add(1);
        }

        if (!didGroupMemberExistBeforeNow) {}

        _updateCycle(cycle);
    }

    // function getMember(address payable depositor, bool throwOnNotFound)
    //     external
    //     returns (Member memory)
    // {
    //     return _getMember(depositor, throwOnNotFound);
    // }

     function _getMember(address payable depositor, bool throwOnNotFound)
        internal
        returns (Member memory)
    {
        bool memberExists = groupStorage.doesMemberExist(depositor);
        if (throwOnNotFound) require(memberExists == true, "Member not found");

        if (!memberExists) {
            groupStorage.createMember(depositor);
        }

        return Member(true, depositor);
    }

     function _updateCycleFinancials(CycleFinancial memory cycleFinancial)
        internal
    {
        cycleStorage.updateCycleFinancials(
            cycleFinancial.cycleId,
            cycleFinancial.underlyingTotalDeposits,
            cycleFinancial.underlyingTotalWithdrawn,
            cycleFinancial.underlyingBalance,
            cycleFinancial.derivativeBalance,
            cycleFinancial.underylingBalanceClaimedBeforeMaturity,
            cycleFinancial.derivativeBalanceClaimedBeforeMaturity
        );
    }

     function _lendCycleDeposit(
        uint256 allowance,
        uint256 amountToDeductFromClient
    ) internal returns (uint256) {
        require(
            allowance >= amountToDeductFromClient,
            "Approve an amount to cover for stake purchase [1]"
        );

        stakedToken.safeTransferFrom(
            msg.sender,
            address(this),
            amountToDeductFromClient
        );



        bool isSuccessful = stakedToken.approve(
            daiLendingService.GetDUSDLendingAdapterAddress(),
            amountToDeductFromClient
        );

        require(isSuccessful == true, "approval to dai lending adapter failed");


        uint256 balanceBeforeDeposit = derivativeToken.balanceOf(address(this));

        daiLendingService.Save(amountToDeductFromClient);


        uint256 balanceAfterDeposit = derivativeToken.balanceOf(address(this));

        uint256 amountOfyDai = balanceAfterDeposit.sub(balanceBeforeDeposit);

         return amountOfyDai;
    }

    function _updateCycleStakeDeposit(
        Cycle memory cycle,
        CycleFinancial memory cycleFinancial,
        uint256 numberOfCycleStakes
    ) internal returns (Cycle memory) {
        cycle.totalStakes = cycle.totalStakes.add(numberOfCycleStakes);

        uint256 depositAmount = cycle.cycleStakeAmount.mul(numberOfCycleStakes);
        cycleFinancial.underlyingTotalDeposits = cycleFinancial
            .underlyingTotalDeposits
            .add(depositAmount);
        _updateCycleFinancials(cycleFinancial);
        _updateTotalTokenDepositAmount(depositAmount);
        return cycle;
    }

    function _updateTotalTokenDepositAmount(uint256 amount) internal {
        groupStorage.incrementTokenDeposit(TokenAddress, amount);
    }

      function _getGroupMember(
        address payable depositor,
        uint256 groupId,
        bool throwOnNotFound
    ) internal returns (GroupMember memory) {
        bool groupMemberExists =
            groupStorage.doesGroupMemberExist(groupId, depositor);

        if (throwOnNotFound)
            require(groupMemberExists == true, "Member not found");

        if (!groupMemberExists) {
            groupStorage.createGroupMember(groupId, depositor);
        }

        return GroupMember(true, depositor, groupId);
    }

      function _createGroupMemberIfNotExist(
        address payable depositor,
        uint256 groupId
    ) internal returns (GroupMember memory) {
        GroupMember memory groupMember = _getGroupMember(depositor, groupId, false);
        return groupMember;
    }

    function _startCycle(Cycle memory cycle) internal {
        cycle.cycleStatus = CycleStatus.ONGOING;
        _updateCycle(cycle);
    }

    function _endCycle(Cycle memory cycle) internal {
        cycle.cycleStatus = CycleStatus.ENDED;
        _updateCycle(cycle);
    }

    function _updateCycle(Cycle memory cycle) internal {
        cycleStorage.updateCycle(
            cycle.id,
            cycle.numberOfDepositors,
            cycle.cycleStartTimeStamp,
            cycle.cycleDuration,
            cycle.maximumSlots,
            cycle.hasMaximumSlots,
            cycle.cycleStakeAmount,
            cycle.totalStakes,
            cycle.stakesClaimed,
            cycle.cycleStatus,
            cycle.stakesClaimedBeforeMaturity
        );
    }

      function _CreateCycleMember(CycleMember memory cycleMember)
        internal
        returns (CycleMember memory)
    {
        cycleStorage.createCycleMember(
            cycleMember.cycleId,
            cycleMember.groupId,
            cycleMember._address,
            cycleMember.totalLiquidityAsPenalty,
            cycleMember.numberOfCycleStakes,
            cycleMember.stakesClaimed,
            cycleMember.hasWithdrawn
        );
    }

    
    function _endCycle(uint256 cycleId)
        internal
        returns (Cycle memory, CycleFinancial memory)
    {
        bool isCycleReadyToBeEnded = xendFinanceGroupHelpers.isCycleReadyToBeEnded(cycleId); 
        require(isCycleReadyToBeEnded == true, "Cycle is still ongoing");

        Cycle memory cycle = xendFinanceGroupHelpers.getCycleById(cycleId);
        CycleFinancial memory cycleFinancial = xendFinanceGroupHelpers.getCycleFinancialByCycleId(cycleId);

        uint256 derivativeBalanceToWithdraw =
            cycleFinancial.derivativeBalance -
                cycleFinancial.derivativeBalanceClaimedBeforeMaturity;

        derivativeToken.approve(
            daiLendingService.GetDUSDLendingAdapterAddress(),
            derivativeBalanceToWithdraw
        );

        uint256 underlyingAmount = _redeemLending(derivativeBalanceToWithdraw);

        cycleFinancial.underlyingBalance = cycleFinancial.underlyingBalance.add(
            underlyingAmount
        );

        cycle.cycleStatus = CycleStatus.ENDED;

        return (cycle, cycleFinancial);
    }

    function _withdrawFromCycleWhileItIsOngoing(
        uint256 cycleId,
        address payable memberAddress
    ) internal {
        bool isCycleReadyToBeEnded = xendFinanceGroupHelpers.isCycleReadyToBeEnded(cycleId);

        require(
            isCycleReadyToBeEnded == false,
            "Cycle has already ended, use normal withdrawl route"
        );

        Cycle memory cycle = xendFinanceGroupHelpers.getCycleById(cycleId);
        CycleFinancial memory cycleFinancial = xendFinanceGroupHelpers.getCycleFinancialByCycleId(cycleId);
        bool memberExistInCycle =
            cycleStorage.doesCycleMemberExist(cycleId, memberAddress);

        require(
            memberExistInCycle == true,
            "You are not a member of this cycle"
        );

        uint256 index = xendFinanceGroupHelpers.getCycleMemberIndex(cycleId, memberAddress);

        CycleMember memory cycleMember = xendFinanceGroupHelpers.getCycleMemberByIndex(index); 

        require(
            cycleMember.hasWithdrawn == false,
            "Funds have already been withdrawn"
        );

        // get's the worth of one stake of the cycle in the derivative amount e.g yDAI
        uint256 derivativeAmountForStake =
            cycleFinancial.derivativeBalance.sub(cycleFinancial.derivativeBalanceClaimedBeforeMaturity).div(cycle.totalStakes);

        //get's how much of a crypto asset the user has deposited. e.g yDAI
        uint256 derivativeBalanceForMember =
            derivativeAmountForStake.mul(cycleMember.numberOfCycleStakes);

      
        //get's the crypto equivalent of a members derivative balance. Crytpo here refers to DAI. this is gotten after the user's ydai balance has been converted to dai
      
         uint256 underlyingAmountThatMemberDepositIsWorth = _redeemLending(derivativeBalanceForMember);

    


        uint256 initialUnderlyingDepositByMember =
            cycleMember.numberOfCycleStakes.mul(cycle.cycleStakeAmount);

        //deduct charges for early withdrawal
        uint256 amountToChargeAsPenalites =
            _computeAmountToChargeAsPenalites(
                underlyingAmountThatMemberDepositIsWorth
            );
      

        underlyingAmountThatMemberDepositIsWorth  = underlyingAmountThatMemberDepositIsWorth.sub(amountToChargeAsPenalites);

        WithdrawalResolution memory withdrawalResolution =
            _computeAmountToSendToParties(
                initialUnderlyingDepositByMember,
                underlyingAmountThatMemberDepositIsWorth
            );

        withdrawalResolution.amountToSendToTreasury = withdrawalResolution
            .amountToSendToTreasury
            .add(amountToChargeAsPenalites);

        if (withdrawalResolution.amountToSendToTreasury > 0) {
            stakedToken.approve(
                TreasuryAddress,
                withdrawalResolution.amountToSendToTreasury
            );
            treasury.depositToken(TokenAddress);
        }

        require(
            withdrawalResolution.amountToSendToMember > 0,
            "After deducting early withdrawal penalties and fees, there's nothing left for you"
        );
        if (withdrawalResolution.amountToSendToMember > 0) {
            stakedToken.safeTransfer(
                cycleMember._address,
                withdrawalResolution.amountToSendToMember
            );
        }

        uint256 totalUnderlyingAmountSentOut =
            withdrawalResolution.amountToSendToTreasury +
                withdrawalResolution.amountToSendToMember;

        cycle.stakesClaimedBeforeMaturity = cycle.stakesClaimedBeforeMaturity.add(cycleMember.numberOfCycleStakes);
        cycleFinancial
            .underylingBalanceClaimedBeforeMaturity = cycleFinancial.underylingBalanceClaimedBeforeMaturity.add(totalUnderlyingAmountSentOut);

        cycleFinancial
            .derivativeBalanceClaimedBeforeMaturity = cycleFinancial.derivativeBalanceClaimedBeforeMaturity.add(derivativeBalanceForMember);

        cycleMember.hasWithdrawn = true;
        cycleMember.stakesClaimed = cycleMember.stakesClaimed.add(cycleMember.numberOfCycleStakes);

        _updateCycle(cycle);
        _updateCycleMember(cycleMember);
        _updateCycleFinancials(cycleFinancial);
    }

     function _redeemLending(uint256 derivativeBalance)
        internal
        returns (uint256)
    {
        require(
            derivativeBalance > 0,
            "Derivative balance must be greater than 0"
        );

        uint256 balanceBeforeWithdraw = stakedToken.balanceOf(address(this));

        bool isSuccessful =
            derivativeToken.approve(
                daiLendingService.GetDUSDLendingAdapterAddress(),
                derivativeBalance
            );

        require(isSuccessful == true, "Approval for withdrawal failed");

        daiLendingService.WithdrawBySharesOnly(derivativeBalance);

        uint256 balanceAfterWithdraw = stakedToken.balanceOf(address(this));

        uint256 amountOfUnderlyingAssetWithdrawn =
            balanceAfterWithdraw.sub(balanceBeforeWithdraw);

        return amountOfUnderlyingAssetWithdrawn;
    }

  function _updateCycleMember(CycleMember memory cycleMember) internal {
        (
            uint256 cycleId,
            address payable depositor,
            uint256 totalLiquidityAsPenalty,
            uint256 numberOfCycleStakes,
            uint256 stakesClaimed,
            bool hasWithdrawn
        ) =
            (
                cycleMember.cycleId,
                cycleMember._address,
                cycleMember.totalLiquidityAsPenalty,
                cycleMember.numberOfCycleStakes,
                cycleMember.stakesClaimed,
                cycleMember.hasWithdrawn
            );
        cycleStorage.updateCycleMember(
            cycleId,
            depositor,
            totalLiquidityAsPenalty,
            numberOfCycleStakes,
            stakesClaimed,
            hasWithdrawn
        );
    }
    function getDerivativeAmountForUserStake(
        uint256 cycleId,
        address payable memberAddress
    ) external view returns (uint256) {
       //todo read from helper
    }

    function withdrawFromCycle(uint256 cycleId)
        external
        onlyNonDeprecatedCalls
    {
        address payable memberAddress = msg.sender;
        uint256 amountToSendToMember =
            _withdrawFromCycle(cycleId, memberAddress);
    }

    function withdrawFromCycle(
        uint256 cycleId,
        address payable memberAddress
    ) external onlyNonDeprecatedCalls {
        uint256 amountToSendToMember =
            _withdrawFromCycle(cycleId, memberAddress);
    }

    function _withdrawFromCycle(uint256 cycleId, address payable memberAddress)
        internal
        returns (uint256 amountToSendToMember)
    {
        Cycle memory cycle;
        CycleFinancial memory cycleFinancial;

        if (xendFinanceGroupHelpers.isCycleReadyToBeEnded(cycleId)) {
            (cycle, cycleFinancial) = _endCycle(cycleId);
        } else {
            cycle = xendFinanceGroupHelpers.getCycleById(cycleId);
            cycleFinancial = xendFinanceGroupHelpers.getCycleFinancialByCycleId(cycleId);
        }

       
        require(
             cycleStorage.doesCycleMemberExist(cycleId, memberAddress) == true,
            "You are not a member of this cycle"
        );

        uint256 index = xendFinanceGroupHelpers.getCycleMemberIndex(cycleId, memberAddress);
        CycleMember memory cycleMember = xendFinanceGroupHelpers.getCycleMemberByIndex(index);

        require(
            cycleMember.hasWithdrawn == false,
            "Funds have already been withdrawn"
        );

        //how many stakes a cycle member has
        uint256 stakesHoldings = cycleMember.numberOfCycleStakes;

        //getting the underlying asset amount that backs 1 stake amount
        uint256 totalStakesLeftWhenTheCycleEnded =
            cycle.totalStakes - cycle.stakesClaimedBeforeMaturity;
        uint256 underlyingAssetForStake =
            cycleFinancial.underlyingBalance.div(
                totalStakesLeftWhenTheCycleEnded
            );

        //cycle members stake amount current worth

        uint256 underlyingAmountThatMemberDepositIsWorth =
            underlyingAssetForStake.mul(stakesHoldings);

        uint256 initialUnderlyingDepositByMember =
            stakesHoldings.mul(cycle.cycleStakeAmount);

        //deduct xend finance fees
        uint256 amountToChargeAsFees =
            _computeXendFinanceCommisions(
                underlyingAmountThatMemberDepositIsWorth, initialUnderlyingDepositByMember
            );
        uint256 creatorReward =
            amountToChargeAsFees.mul(_groupCreatorRewardPercent).div(
                _getFeePrecision().mul(100)
            );

        uint256 finalAmountToChargeAsFees =
            amountToChargeAsFees.sub(creatorReward);

        underlyingAmountThatMemberDepositIsWorth = underlyingAmountThatMemberDepositIsWorth
            .sub(finalAmountToChargeAsFees.add(creatorReward));

        WithdrawalResolution memory withdrawalResolution =
            _computeAmountToSendToParties(
                initialUnderlyingDepositByMember,
                underlyingAmountThatMemberDepositIsWorth
            );

        withdrawalResolution.amountToSendToTreasury = withdrawalResolution
            .amountToSendToTreasury
            .add(finalAmountToChargeAsFees);

        if (withdrawalResolution.amountToSendToTreasury > 0) {
            stakedToken.approve(
                TreasuryAddress,
                withdrawalResolution.amountToSendToTreasury
            );
            treasury.depositToken(TokenAddress);

            stakedToken.safeTransfer(
                xendFinanceGroupHelpers.getGroupCreator(cycleMember.groupId),
                creatorReward
            );
        }

        if (withdrawalResolution.amountToSendToMember > 0) {
            stakedToken.safeTransfer(
                cycleMember._address,
                withdrawalResolution.amountToSendToMember
            );
        }

        uint256 totalUnderlyingAmountSentOut =
            withdrawalResolution.amountToSendToTreasury +
                withdrawalResolution.amountToSendToMember;

        cycle.stakesClaimed = cycle.stakesClaimed.add(stakesHoldings);
        cycleFinancial.underlyingTotalWithdrawn = cycleFinancial.underlyingTotalWithdrawn.add(totalUnderlyingAmountSentOut);

        cycleMember.hasWithdrawn = true;
        cycleMember.stakesClaimed = cycleMember.stakesClaimed.add(stakesHoldings);

        _rewardUserWithTokens(
            cycle.cycleDuration,
            initialUnderlyingDepositByMember,
            cycleMember._address
        );

        _updateCycle(cycle);
        _updateCycleFinancials(cycleFinancial);
        _updateCycleMember(cycleMember);

        return withdrawalResolution.amountToSendToMember;

    }

  

    function deprecateContract(address newServiceAddress)
        external
        onlyOwner
        onlyNonDeprecatedCalls
    {
        isDeprecated = true;
        groupStorage.reAssignStorageOracle(newServiceAddress);
        cycleStorage.reAssignStorageOracle(newServiceAddress);
        uint256 derivativeTokenBalance =
            derivativeToken.balanceOf(address(this));
        derivativeToken.transfer(newServiceAddress, derivativeTokenBalance);
        stakedToken.safeTransfer(
            newServiceAddress,
            stakedToken.balanceOf(address(this))
        );
    }

    
        function updateRewardBridgeAddress(address newRewardBridgeAddress) external onlyOwner{
        require(newRewardBridgeAddress!=address(0x0),"Invalid address");
        require(newRewardBridgeAddress.isContract(),"Invalid contract address");
        rewardBridge = IRewardBridge(newRewardBridgeAddress);
    }

    function _emitXendTokenReward(address payable member, uint256 amount)
        internal
    {
        emit XendTokenReward(now, member, amount);
    }

    function _rewardUserWithTokens(
        uint256 totalCycleTimeInSeconds,
        uint256 amountDeposited,
        address payable cycleMemberAddress
    ) internal {
        uint256 numberOfRewardTokens =
            rewardConfig.CalculateCooperativeSavingsReward(
                totalCycleTimeInSeconds,
                amountDeposited
            );

        if (numberOfRewardTokens > 0) {
            rewardBridge.rewardUser(numberOfRewardTokens,cycleMemberAddress);

            groupStorage.setXendTokensReward(
                cycleMemberAddress,
                numberOfRewardTokens
            );

            _emitXendTokenReward(cycleMemberAddress, numberOfRewardTokens);
        }
    }

    function _computeAmountToChargeAsPenalites(uint256 worthOfMemberDepositNow)
        internal
        returns (uint256)
    {
        (
            uint256 minimum,
            uint256 maximum,
            uint256 exact,
            bool applies,
            RuleDefinition ruleDefinition
        ) = savingsConfig.getRuleSet(PERCENTAGE_AS_PENALTY);

        require(applies == true, "unsupported rule defintion for rule set");

        require(
            ruleDefinition == RuleDefinition.VALUE,
            "unsupported rule defintion for penalty percentage rule set"
        );

        require(
            worthOfMemberDepositNow > 0,
            "member deposit really isn't worth much"
        );

        uint256 amountToChargeAsPenalites =
            worthOfMemberDepositNow.mul(exact).div(100);
        return amountToChargeAsPenalites;
    }

   function _computeXendFinanceCommisions(uint256 worthOfMemberDepositNow, uint256 initialAmountDeposited)
        internal
        returns (uint256)
    {
        uint256 dividend = _getDividend();
        uint256 feePrecision = _getFeePrecision();

        require(
            worthOfMemberDepositNow > 0,
            "member deposit really isn't worth much"
        );

        if(worthOfMemberDepositNow>initialAmountDeposited){
            uint256 profit = worthOfMemberDepositNow.sub(initialAmountDeposited);
            return ((profit.mul(dividend)).div(feePrecision)).div(100);
        }
        else{
            return 0;
        }

    }

    function _getFeePrecision() internal returns (uint256) {
        (,,uint256 feePrecision,bool appliesDividend,RuleDefinition ruleDefinition) = savingsConfig.getRuleSet(XEND_FEE_PRECISION);

        require(appliesDividend, "unsupported rule defintion for rule set");

        require(
            ruleDefinition == RuleDefinition.VALUE,
            "unsupported rule defintion for fee precision"
        );
        return feePrecision;
    }

    function _getDividend() internal returns (uint256) {
        (
            uint256 minimumDividend,
            uint256 maximumDividend,
            uint256 exactDividend,
            bool appliesDividend,
            RuleDefinition ruleDefinitionDividend
        ) = savingsConfig.getRuleSet(XEND_FINANCE_COMMISION_DIVIDEND);

        require(
            appliesDividend == true,
            "unsupported rule defintion for rule set"
        );

        require(
            ruleDefinitionDividend == RuleDefinition.VALUE,
            "unsupported rule defintion for penalty percentage rule set"
        );
        return exactDividend;
    }

    //Determines how much we send to the treasury and how much we send to the member
    function _computeAmountToSendToParties(
        uint256 totalUnderlyingAmountMemberDeposited,
        uint256 worthOfMemberDepositNow
    ) internal returns (WithdrawalResolution memory) {
        (
            uint256 minimum,
            uint256 maximum,
            uint256 exact,
            bool applies,
            RuleDefinition ruleDefinition
        ) = savingsConfig.getRuleSet(PERCENTAGE_PAYOUT_TO_USERS);

        require(applies == true, "unsupported rule defintion for rule set");

        require(
            ruleDefinition == RuleDefinition.VALUE,
            "unsupported rule defintion for payout  percentage rule set"
        );

        //ensures we send what the user's investment is currently worth when his original deposit did not appreciate in value
        if (totalUnderlyingAmountMemberDeposited >= worthOfMemberDepositNow) {
            return WithdrawalResolution(worthOfMemberDepositNow, 0);
        } else {
            uint256 maxAmountUserCanBePaid =
                _getMaxAmountUserCanBePaidConsideringInterestLimit(
                    exact,
                    totalUnderlyingAmountMemberDeposited
                );

            if (worthOfMemberDepositNow > maxAmountUserCanBePaid) {
                uint256 amountToSendToTreasury =
                    worthOfMemberDepositNow.sub(maxAmountUserCanBePaid);
                return
                    WithdrawalResolution(
                        maxAmountUserCanBePaid,
                        amountToSendToTreasury
                    );
            } else {
                return WithdrawalResolution(worthOfMemberDepositNow, 0);
            }
        }
    }

    function _getMaxAmountUserCanBePaidConsideringInterestLimit(
        uint256 maxPayoutPercentage,
        uint256 totalUnderlyingAmountMemberDeposited
    ) internal returns (uint256) {
        uint256 percentageConsideration = 100 + maxPayoutPercentage;
        return
            totalUnderlyingAmountMemberDeposited
                .mul(percentageConsideration)
                .div(100);
    }

    function _addDepositorToCycle(
        uint256 cycleId,
        uint256 cycleAmountForStake,
        uint256 numberOfStakes,
        uint256 amountToDeductFromClient,
        address payable depositorAddress
    ) internal returns (CycleDepositResult memory) {
        Group memory group = xendFinanceGroupHelpers.getCycleGroup(cycleId);

        Member memory member = _createMemberIfNotExist(depositorAddress);
        GroupMember memory groupMember =
            _createGroupMemberIfNotExist(depositorAddress, group.id);

        bool doesCycleMemberExist =
            cycleStorage.doesCycleMemberExist(cycleId, depositorAddress);

        CycleMember memory cycleMember =
            CycleMember(
                true,
                cycleId,
                group.id,
                depositorAddress,
                0,
                0,
                0,
                false
            );

        if (doesCycleMemberExist) {
            cycleMember = xendFinanceGroupHelpers.getCycleMemberByAddressAndCycleId(depositorAddress, cycleId);
        }

        uint256 underlyingAmount = amountToDeductFromClient;

        cycleMember = _saveMemberDeposit(
            doesCycleMemberExist,
            cycleMember,
            numberOfStakes
        );

        CycleDepositResult memory result =
            CycleDepositResult(
                group,
                member,
                groupMember,
                cycleMember,
                underlyingAmount
            );

        return result;
    }

    function _saveMemberDeposit(
        bool didCycleMemberExistBeforeNow,
        CycleMember memory cycleMember,
        uint256 numberOfCycleStakes
    ) internal returns (CycleMember memory) {
        cycleMember.numberOfCycleStakes = cycleMember.numberOfCycleStakes.add(
            numberOfCycleStakes
        );

        if (didCycleMemberExistBeforeNow == true)
            _updateCycleMember(cycleMember);
        else _CreateCycleMember(cycleMember);

        return cycleMember;
    }

    // function getRecordIndexLengthForCycleMembers(uint256 cycleId)
    //     external
    //     view
    //     onlyNonDeprecatedCalls
    //     returns (uint256)
    // {
    //     return cycleStorage.getRecordIndexLengthForCycleMembers(cycleId);
    // }

    // function getRecordIndexLengthForCycleMembersByDepositor(
    //     address depositorAddress
    // ) external view onlyNonDeprecatedCalls returns (uint256) {
    //     return
    //         cycleStorage.getRecordIndexLengthForCycleMembersByDepositor(
    //             depositorAddress
    //         );
    // }

    // function getRecordIndexLengthForGroupMembers(uint256 groupId)
    //     external
    //     view
    //     onlyNonDeprecatedCalls
    //     returns (uint256)
    // {
    //     return groupStorage.getRecordIndexLengthForGroupMembersIndexer(groupId);
    // }

    // function getRecordIndexLengthForGroupMembersByDepositor(
    //     address depositorAddress
    // ) external view onlyNonDeprecatedCalls returns (uint256) {
    //     return
    //         groupStorage.getRecordIndexLengthForGroupMembersIndexerByDepositor(
    //             depositorAddress
    //         );
    // }

    // function getRecordIndexLengthForGroupCycles(uint256 groupId)
    //     external
    //     view
    //     onlyNonDeprecatedCalls
    //     returns (uint256)
    // {
    //     return cycleStorage.getRecordIndexLengthForGroupCycleIndexer(groupId);
    // }

    // function getRecordIndexLengthForCreator(address groupCreator)
    //     external
    //     view
    //     onlyNonDeprecatedCalls
    //     returns (uint256)
    // {
    //     return groupStorage.getRecordIndexLengthForCreator(groupCreator);
    // }

    function getSecondsLeftForCycleToEnd(uint256 cycleId)
        external
        view
        onlyNonDeprecatedCalls
        returns (uint256)
    {
        Cycle memory cycle = xendFinanceGroupHelpers.getCycleById(cycleId);
        require(cycle.cycleStatus == CycleStatus.ONGOING);
        uint256 cycleEndTimeStamp =
            cycle.cycleStartTimeStamp + cycle.cycleDuration;

        if (cycleEndTimeStamp >= now) return cycleEndTimeStamp - now;
        else return 0;
    }

    function getSecondsLeftForCycleToStart(uint256 cycleId)
        external
        view
        onlyNonDeprecatedCalls
        returns (uint256)
    {
        Cycle memory cycle = xendFinanceGroupHelpers.getCycleById(cycleId);
        require(cycle.cycleStatus == CycleStatus.NOT_STARTED);

        if (cycle.cycleStartTimeStamp >= now)
            return cycle.cycleStartTimeStamp - now;
        else return 0;
    }

    function activateCycle(uint256 cycleId)
        external
        onlyNonDeprecatedCalls
        onlyCycleCreator(cycleId)
    {
        Cycle memory cycle = xendFinanceGroupHelpers.getCycleById(cycleId);
        CycleFinancial memory cycleFinancial =
            xendFinanceGroupHelpers.getCycleFinancialByCycleId(cycleId);

        uint256 currentTimeStamp = now;
        require(
            cycle.cycleStatus == CycleStatus.NOT_STARTED,
            "Cannot activate a cycle not in the 'NOT_STARTED' state"
        );
        require(
            cycle.numberOfDepositors > 0,
            "Cannot activate cycle that has no depositors"
        );

        require(
            cycle.cycleStartTimeStamp <= currentTimeStamp,
            "Cycle start time has not been reached"
        );

        cycle.cycleStartTimeStamp = currentTimeStamp;
        _startCycle(cycle);

        uint256 blockNumber = block.number;
        uint256 blockTimestamp = currentTimeStamp;

        emit CycleStarted(cycleId, cycle.cycleStartTimeStamp);
    }

    function endCycle(uint256 cycleId) external onlyNonDeprecatedCalls {
        Cycle memory cycle;
        CycleFinancial memory cycleFinancial;
        (cycle, cycleFinancial) = _endCycle(cycleId);
        _updateCycle(cycle);
        _updateCycleFinancials(cycleFinancial);
    }

    function createGroup(string calldata name, string calldata symbol)
        external
        onlyNonDeprecatedCalls
    {
        xendFinanceGroupHelpers.validateGroupNameAndSymbolIsAvailable(name, symbol);

        uint256 groupId = groupStorage.createGroup(name, symbol, msg.sender);

        emit GroupCreated(groupId, msg.sender);
    }

  

    function createCycle(
        uint256 groupId,
        uint256 startTimeStamp,
        uint256 duration,
        uint256 maximumSlots,
        bool hasMaximumSlots,
        uint256 cycleStakeAmount
    ) external onlyNonDeprecatedCalls onlyGroupCreator(groupId) {
        xendFinanceGroupHelpers.validateCycleCreationActionValid(
            groupId,
            maximumSlots,
            hasMaximumSlots
        );

        uint256 cycleId =
            cycleStorage.createCycle(
                groupId,
                0,
                startTimeStamp,
                duration,
                maximumSlots,
                hasMaximumSlots,
                cycleStakeAmount,
                0,
                0,
                CycleStatus.NOT_STARTED,
                0
            );

        cycleStorage.createCycleFinancials(cycleId, groupId, 0, 0, 0, 0, 0, 0);

        emit CycleCreated(
            cycleId,
            maximumSlots,
            hasMaximumSlots,
            cycleStakeAmount,
            startTimeStamp,
            duration
        );
    }

    function joinCycle(uint256 cycleId, uint256 numberOfStakes)
        external
        onlyNonDeprecatedCalls
    {
        address payable depositorAddress = msg.sender;
        uint256 allowance = _getAllowanceForBusd();

        _joinCycle(cycleId, numberOfStakes, allowance, depositorAddress);
    }

     function getAllowanceForBusd() external view returns (uint256) {
        return _getAllowanceForBusd();
    }

     function _getAllowanceForBusd() internal view returns (uint256) {
        address recipient = address(this);
        uint256 amountDepositedByUser =
            stakedToken.allowance(msg.sender, recipient);
        require(
            amountDepositedByUser > 0,
            "Approve an amount to cover for stake purchase [0]"
        );

        return amountDepositedByUser;
    }

    function joinCycleDelegate(
        uint256 cycleId,
        uint256 numberOfStakes,
        address payable depositorAddress
    ) external onlyNonDeprecatedCalls onlyOwner{
        uint256 allowance = _getAllowanceForBusd();

        _joinCycle(cycleId, numberOfStakes, allowance, depositorAddress);
    }

    function withdrawTokens(address tokenAddress) external onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        uint256 balance =  token.balanceOf(address(this));
        token.safeTransfer(owner,balance);        
    }

    modifier onlyCycleCreator(uint256 cycleId) {
        Group memory group = xendFinanceGroupHelpers.getCycleGroup(cycleId);

        bool isCreatorOrMember = (msg.sender == group.creatorAddress);

        if (isCreatorOrMember == false) {
            uint256 index = xendFinanceGroupHelpers.getCycleMemberIndex(cycleId, msg.sender);
            CycleMember memory cycleMember = xendFinanceGroupHelpers.getCycleMemberByIndex(index);

            isCreatorOrMember = (cycleMember._address == msg.sender);
        }

        require(isCreatorOrMember == true, "unauthorized access to contract");
        _;
    }

    modifier onlyGroupCreator(uint256 groupId) {
        Group memory group = xendFinanceGroupHelpers.getGroup(groupId);

        require(
            msg.sender == group.creatorAddress,
            "unauthorized access to contract"
        );
        _;
    }
}
