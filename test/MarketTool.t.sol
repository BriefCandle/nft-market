pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import 'src/example/NFT2.sol';
import "src/Markettool.sol";
import 'src/Market.sol';
import 'src/MarketFactory.sol';

contract MarketToolTest is Test {
    NFT2 nft;
    Market market;
    MarketFactory factory;
    MarketTool tool;

    address internal alice;
    address internal bob;

    function setUp() public {
        nft = new NFT2("a", "b");
        factory = new MarketFactory();
        market = Market(factory.createMarket(address(nft)));
        tool = new MarketTool(address(factory));

        alice = address(1); //always the owner
        bob = address(2); //
    }

    function mintApproveAndAsk(address recipient, uint amount) public {
        vm.startPrank(recipient);
        nft.setApprovalForAll(address(market), true);
        for (uint i; i < amount; i++) {
            nft.mintTo(recipient);
            market.sellerAsk(i+1, 1000, 1000);
        }
        vm.stopPrank();
    }

    function testBatchPurchase() payable public {
        mintApproveAndAsk(alice, 3);
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        vm.deal(bob, uint256(3000));
        vm.prank(bob);
        tool.batchPurchase{value: 3000}(address(nft), tokenIds);
    }
}

