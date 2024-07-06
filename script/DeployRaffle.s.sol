// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Raffle-Smart-Contract
 * @author Shah_Hyder 
 * @notice This contract creates a sample Raffle(Lottery-Contract)
 * @dev Implements Chainlink VRFv2
 */

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.sol";
import {InteractionsFund, InteractionsSubscription, InteractionsConsumer} from "./Interactions.s.sol";
import "test/FunctionTest.t.sol";
contract DeployRaffle is Script{

   function run() external returns(Raffle, HelperConfig){
    HelperConfig helperConfig = new HelperConfig();
    (
      uint256 _entranceFee, 
      uint256 _intervel, 
      address _vRFCoordinator, 
      bytes32 _gasLane, 
      uint64 _subscriptionId, 
      uint32 _callbackGasLimit,
      address _link,
      uint256 deployerKey
    ) = helperConfig.activeConfig();

/*Check and/or Create a Subscription */

    if (_subscriptionId == 0) {
      InteractionsSubscription interactionsSubscription = new InteractionsSubscription();
      _subscriptionId = interactionsSubscription.createSubscription(_vRFCoordinator, deployerKey);
    

/*Funding the Contract */

    InteractionsFund interactionsFund = new InteractionsFund();
    interactionsFund.fundSubscription
    ( _link, 
     _vRFCoordinator, 
     _subscriptionId,
     deployerKey);
    }

    vm.startBroadcast();
      Raffle raffle = new Raffle(
          _entranceFee, 
          _intervel, 
          _vRFCoordinator, 
          _gasLane, 
          _subscriptionId, 
          _callbackGasLimit
      );
    vm.stopBroadcast();

    /*Adding a Consumer */

    InteractionsConsumer interactionsConsumer = new InteractionsConsumer();
    interactionsConsumer.mockAddConsumer
    (address(raffle), 
    _vRFCoordinator, 
    _subscriptionId,
    deployerKey);
    
    
    return (raffle, helperConfig);
   }
}