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
import {InteractionsFund, InteractionsSubscription, InteractionsConsumer} from "script/Interactions.s.sol";


contract InteractionsTest {
    
    
}