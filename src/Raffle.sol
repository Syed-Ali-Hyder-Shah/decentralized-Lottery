// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Raffle-Smart-Contract
 * @author Shah_Hyder 
 * @notice This contract creates a sample Raffle(Lottery-Contract)
 * @dev Implements Chainlink VRFv2
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract Raffle is VRFConsumerBaseV2{
   /**Errors */
   error Raffle__NotEnoughEthSent();
   error Raffle__timeElapseError();
   error Raffle__TransferFailed();
   error Raffle__raffleNotOpen();
   
   error Raffle__UpkeepNotNeeded
   (uint256 raffleState,
   uint256 currentBalance,
   uint256 numPlayers
   );
   /**Errors */

   /**Type Declaration */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    RaffleState constant DEFAULT_STATE = RaffleState.CALCULATING;
   /**Type Declaration */

   /**Variables */
   uint16 private constant REQUEST_CONFIRMATIONS = 3;
   uint32 private constant NUM_WORDS = 1;

   uint256 private immutable i_entranceFee;
   uint256 private immutable i_intervel;
   VRFCoordinatorV2Interface private immutable i_vRFCoordinator;
   bytes32 private immutable i_gasLane;
   uint64 private immutable i_subscriptionId;
   uint32 private immutable i_callbackGasLimit;
   
   address payable[] private s_players;
   uint256 private s_lastTimeStamp;
   RaffleState private s_raffleState;
   address payable s_recentWinner;
   /**Variables */

   /**Events */
   event EnteredRaffle(address indexed player);
   event PickedWinner(address indexed winner);
   event RequestedRaffleWinner(uint256 indexed requestId);
   /**Events */


constructor(uint256 _entranceFee, 
uint256 _intervel, 
address _vRFCoordinator, 
bytes32 _gasLane, 
uint64 _subscriptionId, 
uint32 _callbackGasLimit)
VRFConsumerBaseV2(_vRFCoordinator){
    i_entranceFee = _entranceFee;
    i_intervel = _intervel;
    i_vRFCoordinator = VRFCoordinatorV2Interface(_vRFCoordinator);
    i_gasLane = _gasLane;
    i_subscriptionId = _subscriptionId;
    i_callbackGasLimit = _callbackGasLimit;
    s_raffleState = RaffleState.OPEN;
    s_lastTimeStamp = block.timestamp;
}


   function enterRaffle() external payable{

    if(msg.value < i_entranceFee){
        revert Raffle__NotEnoughEthSent();
    }

    if(s_raffleState != RaffleState.OPEN){
        revert Raffle__raffleNotOpen();
    }

    s_players.push(payable(msg.sender));

    emit EnteredRaffle(msg.sender);
   }
/**
 * @dev function checkUpkeep mimics chainLink time automation
 * and considers the following 4 points:
 * 1- the intervel specified is met
 * 2- the raffleState is open
 * 3- contract is funded (which means...)
 * 4- there are players in the contract
 */
   function checkUpkeep(bytes memory /*checkData*/) 
   public view returns(bool upkeepNeeded, bytes memory /*performData*/ ){
    bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) > i_intervel);
    bool isOpen = RaffleState.OPEN == s_raffleState;
    bool hasBalance = address(this).balance > 0;
    bool hasPlayers = s_players.length > 0;
    upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
    return (upkeepNeeded, "0x0");
   }

   function performUpkeep( bytes memory /*performData*/ ) external {
    (bool upkeepNeeded,) = checkUpkeep('');
    if(!upkeepNeeded){
        revert Raffle__UpkeepNotNeeded
        (
   address(this).balance,
   s_players.length,
   uint256(s_raffleState));
    }
    s_raffleState = RaffleState.CALCULATING;
    uint256 requestId = i_vRFCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
   }

   function fulfillRandomWords
   (uint256 /*requestId*/, uint256[] memory randomWords) 
   
   internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable winner = s_players[indexOfWinner];
    s_recentWinner = winner;
    s_raffleState = RaffleState.OPEN;
    s_players = new address payable [](0);
    s_lastTimeStamp = block.timestamp;
    emit PickedWinner(winner);
    (bool callSuccess,) = winner.call{value: address(this).balance}("");
    
    if(!callSuccess){
        revert Raffle__TransferFailed();
    }
   }

   /**Getter Functions */
    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getPlayersFromArray (uint256 i) external view returns (address){
       return s_players[i];
    }

    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }

    function getLastTimeStamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }

    function getResetArrayLength() external view returns(uint256) {
        return s_players.length;
    }
   /**Getter Functions */

   
}