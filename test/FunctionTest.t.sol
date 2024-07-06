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
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Test, console} from "../forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract FunctionTest is Test{
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_MONEY = 10 ether;
    Raffle raffle;
    HelperConfig helperConfig;

      uint256 _entranceFee;
      uint256 _intervel; 
      address _vRFCoordinator; 
      bytes32 _gasLane;
      uint64 _subscriptionId;
      uint32 _callbackGasLimit;
      address _link;
      

      /**Events */
      event EnteredRaffle(address indexed player);
      event PickedWinner(address indexed winner);
      /**Events */

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
         (
       _entranceFee, 
       _intervel, 
       _vRFCoordinator, 
       _gasLane, 
       _subscriptionId, 
       _callbackGasLimit,
       _link,
       
       
    ) = helperConfig.activeConfig(); 
    vm.deal(PLAYER, STARTING_MONEY);
    }
    
    
    modifier checkUpkeepIsDone {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();
      vm.warp(block.timestamp + _intervel + 1);
      vm.roll(block.number + 1);
      _;
    }
    
    function testRaffleStateIsOpen() external view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenLackingFunds() external {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();

    }

    function testRaffleRecordsPlayerWhenTheyEnter() external {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();
      address playerAddress = raffle.getPlayersFromArray(0);
      assert(playerAddress == PLAYER);
    }

    function testEmitsEventOnEntrance() external{
      vm.prank(PLAYER);
      vm.expectEmit(true, false, false, false, address(raffle));
      
      emit EnteredRaffle(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();

    }

    function testCantEnterRaffleWhenCalculating() external {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();
      vm.warp(block.timestamp + _intervel + 1);
      vm.roll(block.number + 1);
      raffle.performUpkeep("");
      
      vm.expectRevert(Raffle.Raffle__raffleNotOpen.selector);
      vm.prank(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();
      
    }

    function testCheckUpKeepReturnsFalseIfHasNoBalance() public {
      vm.warp(block.timestamp + _intervel + 1);
      vm.roll(block.number + 1);

      (bool upkeepNeeded, ) = raffle.checkUpkeep("");

      assert(!upkeepNeeded);

    }

    function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();
      vm.warp(block.timestamp + _intervel + 1);
      vm.roll(block.number + 1);
      raffle.performUpkeep("");

      (bool upkeepNeeded,) = raffle.checkUpkeep('');
      assert(!upkeepNeeded);

    }

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed () public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();
      
      vm.roll(block.number + 1);

      (bool upkeepNeeded, ) = raffle.checkUpkeep("");

      assert(!upkeepNeeded);
    }

    function testCheckUpKeepReturnsTrueWhenParamsAreGood () public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();
      vm.warp(block.timestamp + _intervel + 1);
      vm.roll(block.number + 1);

      (bool upkeepNeeded, ) = raffle.checkUpkeep("");

      assert(upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckupkeepIsTrue() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value: _entranceFee}();
      vm.warp(block.timestamp + _intervel + 1);
      vm.roll(block.number + 1);
       
       raffle.performUpkeep("");

    }

    function testPerformUpkeepRvertsIfCheckUpkeepIsFalse () public{
      uint256 numPlayers = 0;
      uint256 raffleState = 0;
      uint256 balance = 0;

      vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, balance, numPlayers, raffleState));
      raffle.performUpkeep("");
      
    }

    function testPerformUpkeepUpdatesRaffleStateEmitsRequestId() public checkUpkeepIsDone{
      vm.recordLogs();
      raffle.performUpkeep("");
      
      Vm.Log[] memory enteries = vm.getRecordedLogs();
      bytes32 requestId = enteries[1].topics[1]; 
      
      Raffle.RaffleState rState = raffle.getRaffleState();
      
      assert(uint256(rState) == 1);
      assert(uint256(requestId) > 0);
    }

    modifier skipFork {
      if (block.chainid != 31337) {
        return;
      }
      _;
    }


    function testFUlFillRandomWordsCanOnlyBecalledAfterPerformUpkeep
    (uint256 randomRequestId) 
    public skipFork checkUpkeepIsDone{
      
       // Arrange
        // Act / Assert
        vm.expectRevert("nonexistent request");
        
        VRFCoordinatorV2Mock(_vRFCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
      
    }

    function testfFulfillRandomWordsPicksAWinnerthenResetsAndSendsMoney
    () 
    public skipFork checkUpkeepIsDone{
      uint256 index = 1;
      uint256 newEntrants = 5;

      for (uint256 i = index; i < index + newEntrants; i++) {
        address allPlayers = address(uint160(i));
        hoax(allPlayers, STARTING_MONEY);
        raffle.enterRaffle{value: _entranceFee}();
      }

      uint256 prize = _entranceFee * (newEntrants);

      vm.recordLogs();
      raffle.performUpkeep("");
      
      Vm.Log[] memory enteries = vm.getRecordedLogs();
      bytes32 requestId = enteries[1].topics[1]; 
      
      uint256 timeStampBeforeFunctionCall = raffle.getLastTimeStamp();
      
      VRFCoordinatorV2Mock(_vRFCoordinator).fulfillRandomWords
      (uint256(requestId), 
      address(raffle));

      assert(uint256(raffle.getRaffleState()) == 0);
      assert(address(raffle.getRecentWinner()) != address(0));
      assert(timeStampBeforeFunctionCall < raffle.getLastTimeStamp());
      assert(raffle.getResetArrayLength() == 0);
      assert(raffle.getRecentWinner().balance == (prize + STARTING_MONEY));
      
    }

    

    

}