// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import 'src/NFT.sol';

contract NFTAskTest is Test {
    NFT nft;

    address internal alice;
    address internal bob;

    function setUp() public {
        nft = new NFT("a","b");

        alice = address(1); //always the owner
        bob = address(2); //

        vm.prank(alice);
        nft.mintTo(alice);
    }

    function testMintNFT() public {
        assertEq(nft.ownerOf(uint256(1)), alice);
    }

    // --- Test sellerAsk() & sellerCancelAsk()--- //
    function testNotOwnerAsk() public {
        vm.prank(bob);
        vm.expectRevert(bytes("not owner"));
        nft.sellerAsk(uint256(1), uint64(1000), uint32(1000));
    }

    function testNotExistTokenAsk() public {
        vm.prank(alice);
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        nft.sellerAsk(uint256(2), uint64(1000), uint32(1000));
    }

    function testOwnerCancelAsk() public {
        uint256 tokenId = 1;
        aliceAskSuccess(tokenId);
        vm.prank(alice); 
        nft.sellerCancelAsk(tokenId);
        (, address seller, , ,) = nft.askList(tokenId); 
        assertEq(seller, address(0));
    }

    function testNotOwnerCancelAsk() public {
        uint256 tokenId = 1;
        aliceAskSuccess(tokenId);
        vm.prank(bob); 
        vm.expectRevert(bytes("not owner"));
        nft.sellerCancelAsk(tokenId);
    }

    function aliceAskSuccess(uint256 tokenId) public {
        vm.prank(alice);
        nft.sellerAsk(tokenId, uint64(1000), uint32(1000));
        (, address seller, , ,) = nft.askList(tokenId); 
        assertEq(seller, alice);
    }

    // --- Test buyerAsk() --- //
    function testBuyerAcceptSuccess() public {
        uint256 tokenId = 1;
        aliceAskSuccess(tokenId);
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        nft.buyerAcceptAsk{value: 1000}(tokenId);
        assertEq(nft.ownerOf(tokenId), bob);
        assertEq(alice.balance, 1000);
        (, address seller, , ,) = nft.askList(tokenId); 
        assertEq(seller, address(0));
    }

    function testNotEnoughETH() public {
        uint256 tokenId = 1;
        aliceAskSuccess(tokenId);
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        vm.expectRevert(bytes("payment not enough"));
        nft.buyerAcceptAsk{value: 100}(tokenId);
    }

    function testNoAskNoAccept() public {
        uint256 tokenId = 1;
        (, address seller, , ,) = nft.askList(tokenId); 
        assertEq(seller, address(0));
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        vm.expectRevert(bytes("ask has expired, rendering ask invalid"));
        nft.buyerAcceptAsk{value: 1000}(tokenId);
    }

    function testDurationPass() public {
        uint256 tokenId = 1;
        aliceAskSuccess(tokenId);
        vm.deal(bob, uint256(1000));
        uint256 timestamp = block.timestamp;
        vm.warp(timestamp + 2000);
        vm.prank(bob);
        vm.expectRevert(bytes("ask has expired, rendering ask invalid"));
        nft.buyerAcceptAsk{value: 1000}(tokenId);
    }

    function testOwnerTransferred() public {
        uint256 tokenId = 1;
        aliceAskSuccess(tokenId);
        vm.prank(alice);
        nft.transferFrom(alice, bob, tokenId);
        assertEq(nft.ownerOf(tokenId), bob);
        // new owner is not obligated to previous ask offered by previous owner
        vm.deal(bob, uint256(1000));
        vm.prank(bob);
        vm.expectRevert(bytes("owner has changed, rendering ask invalid"));
        nft.buyerAcceptAsk(tokenId);
        // new owner is able to submit new ask 
        // ...
    }

}