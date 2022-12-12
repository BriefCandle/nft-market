pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import 'src/example/NFT2.sol';
import 'src/Market.sol';
import 'src/MarketFactory.sol';

contract MarketAskTest is Test {
    NFT2 nft;
    Market market;
    MarketFactory factory;

    address internal alice;
    address internal bob;

    function setUp() public {
        nft = new NFT2("a", "b");
        factory = new MarketFactory();
        market = Market(factory.createMarket(address(nft)));

        alice = address(1); //always the owner
        bob = address(2); //

        vm.prank(alice);
        nft.mintTo(alice);
    }

    /** 
     * ------------- TEST Market FACTORY -------------
    */
    function testFactoryInfex() public {
        assertEq(factory.getMarket(address(nft)), address(market));
    }

    /** 
     * ------------- TEST SELLER ASK -------------
    */

    function testAliceAskSuccess() public {
        uint256 tokenId = 1;
        aliceSetApproval();
        aliceAsk();
        (, address seller, , ,) = market.getAsk(tokenId); 
        assertEq(seller, alice);
        vm.stopPrank();
    }

    function aliceSetApproval() public {
        vm.prank(alice);
        nft.setApprovalForAll(address(market), true);
    }

    function aliceAsk() public {
        uint256 tokenId = 1;
        vm.prank(alice);
        market.sellerAsk(tokenId, uint64(1000), uint32(1000));
    }

    function testNotOwner() public { // not owner cannot ask for the nft
        uint256 tokenId = 1;
        vm.prank(alice);
        nft.safeTransferFrom(address(alice), address(bob), tokenId);
        assertEq(nft.ownerOf(tokenId), address(bob));
        vm.expectRevert(bytes("Market: not approved"));
        aliceAsk();
    }

    function testNonExistentToken() public { //non-existent token cannot be asked
        vm.prank(alice);
        vm.expectRevert(bytes("Market: not approved")); // not "ERC721: invalid token ID" because approval is check first
        market.sellerAsk(uint256(2), uint64(1000), uint32(1000));
    }

    function testAliceRescindAsk() public { // owner can Rescind ask
        uint256 tokenId = 1;
        testAliceAskSuccess();
        vm.prank(alice);
        market.sellerRescindAsk((tokenId));
        (, address seller, , ,) = market.getAsk(tokenId); 
        assertEq(seller, address(0));
    }

    function testNotOwnerRescindAsk() public {
        uint256 tokenId = 1;
        aliceSetApproval();
        aliceAsk();
        vm.prank(bob); 
        vm.expectRevert(bytes("Market: not owner"));
        market.sellerRescindAsk(tokenId);
    }

    /** 
     * ------------- TEST BUYER ACCEPT -------------
    */

    function testNotEnoughETH() public { // buyer cannot accept with insufficient eth
        uint256 tokenId = 1;
        testAliceAskSuccess();
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        vm.expectRevert(bytes("Market: payment not enough"));
        market.buyerAcceptAsk{value: 100}(tokenId, bob);
    }

    function testNoAskNoAccept() public { // buyer cannot accept when there is no ask
        uint256 tokenId = 1;
        (, address seller, , ,) = market.getAsk(tokenId); 
        assertEq(seller, address(0));
        assertEq(market.checkAskBinding(tokenId), false);
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        vm.expectRevert(bytes('Market: no ask or ask has expired'));
        market.buyerAcceptAsk{value: 1000}(tokenId, bob);  
    }

    function testDurationPass() public { // buyer cannot accept when duration passes
        uint256 tokenId = 1;
        testAliceAskSuccess();
        vm.deal(bob, uint256(1000));
        uint256 timestamp = block.timestamp;
        vm.warp(timestamp + 2000);
        assertEq(market.checkAskBinding(tokenId), false);
        vm.prank(bob);
        vm.expectRevert(bytes('Market: no ask or ask has expired'));
        market.buyerAcceptAsk{value: 1000}(tokenId, bob);
    }

    function testOwnerTransferred() public { 
        // avoid the situation where owner A sets a low price“ask” and transfer/sell 
        // on other Market to B who approves our Market as the operator. 
        // Before B changes the “ask”, anyone can accept A’s previous “ask” and “purchase”
        //  B’s NFT
        uint256 tokenId = 1;
        testAliceAskSuccess();
        // alice set up a low price & transfer to bob
        vm.prank(alice);
        nft.transferFrom(alice, bob, tokenId);
        assertEq(nft.ownerOf(tokenId), bob);
        // bob, now the new owner, is not obligated to previous ask offered by previous owner
        assertEq(market.checkAskBinding(tokenId), false);
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        // let bob setApproval
        nft.setApprovalForAll(address(market), true);
        // alice tries to accept ask
        vm.prank(alice);
        vm.expectRevert(bytes("Market: owner has changed"));
        market.buyerAcceptAsk(tokenId, bob);
        assertEq(market.checkAskBinding(tokenId), false);
        // new owner is able to submit new ask 
        // ...
    }

    function testBobAcceptSuccess() public { // checkAskBinding() returns true
        uint256 tokenId = 1;
        testAliceAskSuccess();
        assertEq(market.checkAskBinding(tokenId), true);
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        market.buyerAcceptAsk{value: 1000}(tokenId, bob);
        assertEq(nft.ownerOf(tokenId), bob);
    }

}