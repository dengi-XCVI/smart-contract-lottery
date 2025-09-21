// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console} from 'forge-std/Script.sol';
import {HelperConfig, CodeConstants} from './HelperConfig.s.sol';
import {VRFCoordinatorV2_5Mock} from '@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol';
import {LinkToken} from '../test/mocks/LinkToken.sol';

contract CreateSubscription is Script {

    // For script standalone usage??
    function createSubscriptionUsingConfig() public returns(uint256, address){
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator= helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address _vrfCoordinator) public returns(uint256, address){
        console.log("Creating subscription on chain Id:", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is:", subId);
        console.log("Please update the subscriptionId in the HelperConfig.s.sol file");
        return (subId,_vrfCoordinator);
    }

    function run() external{
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {

    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscritpionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscritpionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription:", subscriptionId);
        console.log("VRFCoordinator:",vrfCoordinator);
        console.log("On chain id:",block.chainid);
        if (block.chainid == ANVIL_CHAINID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId,FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT,abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() external {}
}