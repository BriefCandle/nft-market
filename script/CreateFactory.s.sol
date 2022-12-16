pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/example/ERC20Token.sol";
import 'src/example/NFTOwnable.sol';
import 'src/Market.sol';
import 'src/MarketFactory.sol';

contract CreateFactoryScript is Script {

    NFTOwnable nft;
    Market market;
    MarketFactory factory;
    ERC20Token erc20;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // vm.broadcast(); 

        factory = new MarketFactory();
        // nft = new NFTOwnable("a", "b");
        // market = Market(factory.createMarket(address(nft)));
        // erc20 = new ERC20Token("a", "b");

        vm.stopBroadcast();
    }
}