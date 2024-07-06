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
import  "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/ChainLinkMock.t.sol";

contract HelperConfig is Script{
    NetworkConfig public activeConfig;
    
    
    constructor(){
       if (block.chainid == 11155111) {
        activeConfig = sepoliaConfig();
       } else {
         activeConfig = getOrCreateAnvilComfig();
       }
    }

    struct NetworkConfig {
      uint256 _entranceFee; 
      uint256 _intervel; 
      address _vRFCoordinator; 
      bytes32 _gasLane; 
      uint64 _subscriptionId; 
      uint32 _callbackGasLimit;
      address _link;
      uint256 deployerKey;
    }

    uint256 public constant DEUFALT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function sepoliaConfig() public view returns(NetworkConfig memory) {
        return NetworkConfig({
       _entranceFee: 0.01 ether,
       _intervel: 30 seconds,
       _vRFCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
       _gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
       _subscriptionId: 0,
       _callbackGasLimit: 500000,
       _link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
       deployerKey: vm.envUint("PRIVATE_KEY")

        });
    }

    function EtheriumComfig() public view returns(NetworkConfig memory) {

    }

    function getOrCreateAnvilComfig() public returns(NetworkConfig memory) {
    
    if(activeConfig._vRFCoordinator != address(0)){
        return activeConfig;
    }
    uint96 _baseFee = 0.25 ether;
    uint96 _gasPriceLink = 1e9;
    vm.startBroadcast();
    VRFCoordinatorV2Mock vrfCordinator = new VRFCoordinatorV2Mock(
       _baseFee,
       _gasPriceLink
    );

    LinkToken linkToken = new LinkToken();
    vm.stopBroadcast();

    return NetworkConfig ({
       _entranceFee: 0.01 ether,
       _intervel: 30 seconds,
       _vRFCoordinator: address(vrfCordinator),
       _gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
       _subscriptionId: 0,
       _callbackGasLimit: 500000,
       _link: address(linkToken),
       deployerKey: DEUFALT_ANVIL_KEY

    }); 
    
    }
}