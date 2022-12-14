pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import 'src/example/NFT2.sol';
import 'src/example/NFTOwnable.sol';
import 'src/Market.sol';
import 'src/MarketFactory.sol';

contract MarketCreatorTest is Test {
    NFT2 nft;
    NFTOwnable nft_ownable;
    Market market_nft;
    Market market_nft_ownable;
    MarketFactory factory;

    address internal alice;
    address internal bob;
    address internal charlie;

    function setUp() public {
        factory = new MarketFactory();

        alice = address(1); // the creator of NFT2
        bob = address(2); // the creator of NFTOwnable
        charlie = address(3); // do the rest transactions

        vm.prank(alice);
        nft = new NFT2("a", "b");
        vm.prank(bob);
        nft_ownable = new NFTOwnable("a", "b");

        market_nft = Market(factory.createMarket(address(nft)));
        market_nft_ownable = Market(factory.createMarket(address(nft_ownable)));
    }

    function testNOTOwnableCannotSetCreator() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Market: no creator setup"));
        market_nft.setCreatorFee(charlie, 2);
    }

    function testOwnableCanSetCreatorOnlyByCreator() public {
        // creator is successfully set
        vm.prank(bob);
        market_nft_ownable.setCreatorFee(charlie, 2);
        assertEq(market_nft_ownable.nft_creator(), bob);
        // not creator cannot set creator
        vm.prank(alice);
        vm.expectRevert(bytes("Market: not creator"));
        market_nft_ownable.setCreatorFee(charlie, 2);
    }
}