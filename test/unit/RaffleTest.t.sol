// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from 'forge-std/Test.sol';
import {DeployRaffle} from 'script/DeployRaffle.s.sol';
import {HelperConfig} from 'script/HelperConfig.s.sol';
import {Raffle} from 'src/Raffle.sol';


contract RaffleTest is Test {

    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 entranceFee;
    uint256 interval;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address vrfCoordinator;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        vm.deal(PLAYER, STARTING_BALANCE);

        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();
        entranceFee = networkConfig.entranceFee;
        interval = networkConfig.interval;
        gasLane = networkConfig.gasLane;
        subscriptionId = networkConfig.subscriptionId;
        callbackGasLimit = networkConfig.callbackGasLimit;
        vrfCoordinator = networkConfig.vrfCoordinator;     
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    } 

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();

    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitRaffleEnteredEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));

        emit RaffleEntered(PLAYER);
        // enter raffle will emit an event that is compared to the above event emitted
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp + interval +1 );
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
    }

} 