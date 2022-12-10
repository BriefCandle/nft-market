pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import 'src/NFT2.sol';
import 'src/NFTMarketplace.sol';
import 'src/NFTMarketplaceFactory.sol';

contract NFTMarketplaceAskTest is Test {
    NFT2 nft;
    NFTMarketplace marketplace;
    NFTMarketplaceFactory factory;

    address internal alice;
    address internal bob;

    function setUp() public {
        nft = new NFT2("a", "b");
        factory = new NFTMarketplaceFactory();
        marketplace = NFTMarketplace(factory.createMarketplace(address(nft)));

        alice = address(1); //always the owner
        bob = address(2); //

        vm.prank(alice);
        nft.mintTo(alice);
    }

    /** 
     * ------------- TEST MARKETPLACE FACTORY -------------
    */
    function testFactoryInfex() public {
        assertEq(factory.getMarketplace(address(nft)), address(marketplace));
    }

    /** 
     * ------------- TEST SELLER ASK -------------
    */

    function testAliceAskSuccess() public {
        uint256 tokenId = 1;
        aliceSetApproval();
        aliceAsk();
        (, address seller, , ,) = marketplace.askList(tokenId); 
        assertEq(seller, alice);
        vm.stopPrank();
    }

    function aliceSetApproval() public {
        vm.prank(alice);
        nft.setApprovalForAll(address(marketplace), true);
    }

    function aliceAsk() public {
        uint256 tokenId = 1;
        vm.prank(alice);
        marketplace.sellerAsk(tokenId, uint64(1000), uint32(1000));
    }

    function testNotOwner() public { // not owner cannot ask for the nft
        uint256 tokenId = 1;
        vm.prank(alice);
        nft.safeTransferFrom(address(alice), address(bob), tokenId);
        assertEq(nft.ownerOf(tokenId), address(bob));
        vm.expectRevert(bytes("not approved"));
        aliceAsk();
    }

    function testNonExistentToken() public { //non-existent token cannot be asked
        vm.prank(alice);
        vm.expectRevert(bytes("not approved")); // not "ERC721: invalid token ID" because approval is check first
        marketplace.sellerAsk(uint256(2), uint64(1000), uint32(1000));
    }

    function testAliceCancelAsk() public { // owner can cancel ask
        uint256 tokenId = 1;
        testAliceAskSuccess();
        vm.prank(alice);
        marketplace.sellerCancelAsk((tokenId));
        (, address seller, , ,) = marketplace.askList(tokenId); 
        assertEq(seller, address(0));
    }

    function testNotOwnerCancelAsk() public {
        uint256 tokenId = 1;
        aliceSetApproval();
        aliceAsk();
        vm.prank(bob); 
        vm.expectRevert(bytes("not owner"));
        marketplace.sellerCancelAsk(tokenId);
    }

    /** 
     * ------------- TEST BUYER ACCEPT -------------
    */

    function testNotEnoughETH() public { // buyer cannot accept with insufficient eth
        uint256 tokenId = 1;
        testAliceAskSuccess();
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        vm.expectRevert(bytes("payment not enough"));
        marketplace.buyerAcceptAsk{value: 100}(tokenId);
    }

    function testNoAskNoAccept() public { // buyer cannot accept when there is no ask
        uint256 tokenId = 1;
        (, address seller, , ,) = marketplace.askList(tokenId); 
        assertEq(seller, address(0));
        assertEq(marketplace.checkAskBinding(tokenId), false);
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        vm.expectRevert(bytes('no ask or ask has expired'));
        marketplace.buyerAcceptAsk{value: 1000}(tokenId);  
    }

    function testDurationPass() public { // buyer cannot accept when duration passes
        uint256 tokenId = 1;
        testAliceAskSuccess();
        vm.deal(bob, uint256(1000));
        uint256 timestamp = block.timestamp;
        vm.warp(timestamp + 2000);
        assertEq(marketplace.checkAskBinding(tokenId), false);
        vm.prank(bob);
        vm.expectRevert(bytes('no ask or ask has expired'));
        marketplace.buyerAcceptAsk{value: 1000}(tokenId);
    }

    function testOwnerTransferred() public { 
        // avoid the situation where owner A sets a low price“ask” and transfer/sell 
        // on other marketplace to B who approves our marketplace as the operator. 
        // Before B changes the “ask”, anyone can accept A’s previous “ask” and “purchase”
        //  B’s NFT
        uint256 tokenId = 1;
        testAliceAskSuccess();
        // alice set up a low price & transfer to bob
        vm.prank(alice);
        nft.transferFrom(alice, bob, tokenId);
        assertEq(nft.ownerOf(tokenId), bob);
        // bob, now the new owner, is not obligated to previous ask offered by previous owner
        assertEq(marketplace.checkAskBinding(tokenId), false);
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        // let bob setApproval
        nft.setApprovalForAll(address(marketplace), true);
        // alice tries to accept ask
        vm.prank(alice);
        vm.expectRevert(bytes("owner has changed"));
        marketplace.buyerAcceptAsk(tokenId);
        assertEq(marketplace.checkAskBinding(tokenId), false);
        // new owner is able to submit new ask 
        // ...
    }

    function testBobAcceptSuccess() public { // checkAskBinding() returns true
        uint256 tokenId = 1;
        testAliceAskSuccess();
        assertEq(marketplace.checkAskBinding(tokenId), true);
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        marketplace.buyerAcceptAsk{value: 1000}(tokenId);
        assertEq(nft.ownerOf(tokenId), bob);
    }

}