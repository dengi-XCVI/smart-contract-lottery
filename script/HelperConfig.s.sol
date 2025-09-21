// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from 'forge-std/Script.sol';
import {Raffle} from '../src/Raffle.sol';
import {VRFCoordinatorV2_5Mock} from '@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol';
import {LinkToken} from '../test/mocks/LinkToken.sol';

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 public constant MAINNET_CHAINID = 1;
    uint256 public constant ANVIL_CHAINID = 31337;

    /* VRF Mock Values */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;
}

contract HelperConfig is Script,CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address vrfCoordinator;
        address link;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAINID] = getSepoliaEthConfig();
    }

    function getConfig() public returns(NetworkConfig memory) {
        return getConfigByChain(block.chainid);
    }

    function getConfigByChain(uint256 chainId) public returns(NetworkConfig memory) {
        if(networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ANVIL_CHAINID){
            return getOrCreateAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }


    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            // Parameters can be found here: https://docs.chain.link/vrf/v2-5/supported-networks
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit:500000, // 500,000 gas
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVrfCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: address(mockVrfCoordinator),
            // doesn't matter, mock makes it work
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit:500000, // 500,000 gas
            link: address(linkToken)
        });
        return localNetworkConfig;

    }

}