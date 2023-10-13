// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

//////////////////////
// Import statements
//////////////////////

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

////////////////////////////
// libraries & Interfaces
////////////////////////////
import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

//////////////////////
// errors
//////////////////////
error Accountable__NotActive();
error Accountable__RefundFailed();
error Accountable__AlreadyJoined();
error Accountable__TransferFailed();
error Accountable__NotEnoughEthSent();
error Accountable__NeedsMoreThanZero();
error Accountable__AlreadyInDeactivation();
error Accountable__StatusIsNotDeactivate();
error Accountable__NoEthSentToIncreaseStake();
error Accountable_MaximumLimitReached(uint256);
error Accountable__NumberOfParticipantsMustBeMoreThanOne();
error Accountable__CanOnlyApproveDeactivationOnce();

/**
 * @title An Accountability application contract
 * @author Mahith Chigurupati
 * @notice This contract is for a group of people who intend to join an agreement for ensuring their timely arrival at any event
 *         this contract will ensure everyone comes to an event on time
 *
 * Days of frustation due to your friend not arriving on time are over!
 * Ever thought of someone making sure everyone does arrives to an event on time feeling the responsibility of doing it right?
 * Here you go ------------------>
 * A protocol to make sure everyone in the agreement feel accountable of their actions.
 *
 * you can find the price of joining agreement interms of USD by calling ***********
 *
 * @dev This contract implements chainlink price feeds for price conversions
 */

contract Accountable is AccessControl {
    //////////////////////
    // Type Declarations
    //////////////////////
    using OracleLib for AggregatorV3Interface;

    /**
     * custon enum variable to hold status of agreement
     */
    enum Status {
        OPEN,
        ACTIVE,
        DEACTIVATION,
        INACTIVE
    }

    //////////////////////
    // State variables
    //////////////////////
    string private s_title;
    uint256 private s_numberOfParticipatingParties;
    uint256 private s_participationStake;
    address payable[] private s_participants;
    uint256 private s_deactivationApprovals;
    mapping(address participant => uint256 balance) private s_participantBalance;
    mapping(address participant => uint256 approval) private s_deactivation;
    Status private s_status;
    address private s_currentChainPriceFeed;

    /////////////////
    // Access Roles
    /////////////////
    bytes32 private constant PARTICIPANT_ROLE = keccak256("PARTICIPANT_ROLE");

    //////////////////////
    // Events to emit
    //////////////////////
    event ParticipantJoinedAgreement(address indexed, uint256);
    event PaticipantIncreasedStake(address indexed, uint256 indexed);
    event AgreementActive(uint256, uint256);
    event DeactiveAgreement(address indexed, string indexed);
    event approvedDeactivation(address);
    event StakeRefunded(address indexed, uint256 indexed);
    event AccountableContractCreated(address, uint256, uint256);

    ///////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Accountable__NeedsMoreThanZero();
        }
        _;
    }

    ///////////////////
    // Functions
    ///////////////////

    /**
     * Constructor called only once during contract deployment
     * @param _title: A title for Agreement
     * @param _numberOfParticipatingParties: Total Number of participating parties/roommates in the contract
     * @param _participationStake: Amount need to be staked by each participant to join the agreement
     */
    constructor(
        string memory _title,
        uint256 _numberOfParticipatingParties,
        uint256 _participationStake,
        address _priceFeedAddressOfcurrentChain
    ) {
        if (_numberOfParticipatingParties <= 1) {
            revert Accountable__NumberOfParticipantsMustBeMoreThanOne();
        }

        s_title = _title;
        s_numberOfParticipatingParties = _numberOfParticipatingParties;
        s_participationStake = _participationStake;
        s_status = Status.OPEN;

        s_currentChainPriceFeed = _priceFeedAddressOfcurrentChain;

        emit AccountableContractCreated(address(this), block.number, block.timestamp);
    }

    /////////////////////////
    // external functions
    /////////////////////////

    /**
     * Participant can join the agreement by staking required ETH
     * called only if ETH or current chains native currency is used as staking fee
     */
    function joinAgreement() external payable {
        // 1. revert if person already joined or maximum persons joined
        // 2. check to ensure enough stake is sent to join the agreement
        // 3. Add the partcipant to contract on succesful check and emit an event for logging
        // 4. make a note of participant's balance
        // 5. If Number of Participants is equal to Number of People joined the agreement, Contract becomes ACTIVE

        if (s_status != Status.OPEN) {
            revert Accountable__NotActive();
        }

        if (s_numberOfParticipatingParties == s_participants.length) {
            revert Accountable_MaximumLimitReached(s_numberOfParticipatingParties);
        }

        if (hasRole(PARTICIPANT_ROLE, msg.sender)) {
            revert Accountable__AlreadyJoined();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_currentChainPriceFeed);

        // a check to see if correct amount of funds are sent to join agreement
        if (priceFeed.getUsdValue(msg.value) < s_participationStake) {
            revert Accountable__NotEnoughEthSent();
        }
        // ETH will be added to current contracts balace by default

        emit ParticipantJoinedAgreement(msg.sender, msg.value);

        _grantRole(PARTICIPANT_ROLE, msg.sender);
        s_participants.push(payable(msg.sender));
        s_participantBalance[msg.sender] = msg.value;

        if (s_participants.length == s_numberOfParticipatingParties) {
            emit AgreementActive(block.number, block.timestamp);
            s_status = Status.ACTIVE;
        }
    }

    /**
     * Participants can increase their stake if falls low on staking balance
     * requirement:
     *   caller must be of PARTICIPANT_ROLE
     */
    function increaseStake() external payable onlyRole(PARTICIPANT_ROLE) {
        if (s_status != Status.ACTIVE) {
            revert Accountable__NotActive();
        }

        if (msg.value > 0) {
            emit PaticipantIncreasedStake(msg.sender, msg.value);
            s_participantBalance[msg.sender] += msg.value;
        } else {
            revert Accountable__NoEthSentToIncreaseStake();
        }
    }

    /**
     * a function must be called by all the participants to accept a task for it to become active
     *
     */
    function acceptTask() external view {
        if (s_status != Status.ACTIVE) {
            revert Accountable__NotActive();
        }

        /*
        */
    }

    /**
     * a function called by all the participants to cast their approval for contract's deactivation
     * @return approvalCount: returns number of approvals received
     *
     * Requirements:
     *   caller must be of PARTICIPANT_ROLE
     */
    function approveDeactivation() external onlyRole(PARTICIPANT_ROLE) returns (uint256) {
        // 1. check if decativation is started
        // 2. check if participant casting the vote has any dues to clear
        // 3. increment the approvalReceived
        // 4. if every participant casts their approval, refund their staking balances of participants if any

        if (s_status != Status.DEACTIVATION) {
            revert Accountable__StatusIsNotDeactivate();
        }

        // check if persona already approved deactivation
        if (s_deactivation[msg.sender] != 0) {
            revert Accountable__CanOnlyApproveDeactivationOnce();
        }

        emit approvedDeactivation(msg.sender);
        s_deactivation[msg.sender] += 1;
        s_deactivationApprovals += 1;

        if (s_deactivationApprovals == getNumberOfParticipatingParties()) {
            _refundEveryone();
            s_status = Status.INACTIVE;
        }

        return s_deactivationApprovals;
    }

    /**
     * a function to initialize deactivation process
     */
    function deactivateContract(string memory reason) external onlyRole(PARTICIPANT_ROLE) {
        if (s_status == Status.DEACTIVATION) {
            revert Accountable__AlreadyInDeactivation();
        }
        emit DeactiveAgreement(msg.sender, reason);
        s_status = Status.DEACTIVATION;
    }

    //////////////////////
    // public functions
    //////////////////////

    /*
    *
    */
    function rewardOthers(address slasher, uint256 _amount) public {
        for (uint256 i = 0; i < s_participants.length; i++) {
            if (s_participants[i] != slasher) {
                s_participantBalance[s_participants[i]] += _amount / s_participants.length;
            }
        }
    }

    //////////////////////////
    // internal functions
    //////////////////////////

    /**
     * an internal refund participant function called to refund staking balance of a participant if any
     * @param _participant: address of participant to be refunded
     */
    function _refundParticipant(address _participant) internal {
        uint256 participantBalance = s_participantBalance[_participant];
        (
            bool success,
            /**
             * data *
             */
        ) = payable(_participant).call{value: participantBalance}("");

        if (success == true) {
            emit StakeRefunded(_participant, s_participantBalance[_participant]);

            s_participantBalance[_participant] -= participantBalance;
        } else {
            revert Accountable__RefundFailed();
        }
    }

    /**
     * An internal function called during deactivation to refund staking balance
     * to every participant after receiving approvals
     */
    function _refundEveryone() internal {
        address payable[] memory participants = s_participants;
        for (uint256 i = 0; i < getNumberOfParticipatingParties(); i++) {
            if (s_participantBalance[participants[i]] > 0) {
                _refundParticipant(participants[i]);
            }
        }
    }

    //////////////////////////////
    // pure and view function
    /////////////////////////////

    /**
     * a function to get titke of contract
     */
    function getTitle() external view returns (string memory) {
        return s_title;
    }

    /**
     * a function to get number of participants in the agreement
     */
    function getNumberOfParticipantsAllowed() public view returns (uint256) {
        return s_numberOfParticipatingParties;
    }

    /**
     * a function to get number of participants in the agreement
     */
    function getNumberOfParticipatingParties() public view returns (uint256) {
        return s_participants.length;
    }

    /**
     * a function to get the staking fee to join the contract in USD
     */
    function getparticipationStake() external view returns (uint256) {
        return s_participationStake;
    }

    /**
     * a function to get the status of contract
     */
    function getStatus() external view returns (uint256) {
        // return uint256(s_status);
    }

    /**
     * a function to get the balance of a particular participant
     */
    function getBalance(address account) external view returns (uint256) {
        return s_participantBalance[account];
    }

    /**
     * a function call to return current chain price feed address
     */
    function getNativeChainPriceFeed() external view returns (address) {
        return s_currentChainPriceFeed;
    }

    /**
     * a function called to get usd price in eth
     */
    function getEthPriceFromUsd(uint256 _amount) external view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_currentChainPriceFeed);
        return priceFeed.getEthAmountFromUsd(_amount);
    }
}
