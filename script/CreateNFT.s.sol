pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import 'src/example/NFTOwnable.sol';

contract CreateNFTScript is Script {
    NFTOwnable nft;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        nft = new NFTOwnable("c", "d");

        vm.stopBroadcast();
    }
}