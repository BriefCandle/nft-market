pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "src/example/ERC20Token.sol";
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
    ERC20Token erc20;

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
        erc20 = new ERC20Token("a", "b");
    }

    function testNOTOwnableCannotSetCreator() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Market: no creator setup"));
        market_nft.setCreatorFee(charlie, 200);
    }

    function testOwnableCanSetCreatorOnlyByCreator() public {
        // creator is successfully set
        vm.prank(bob);
        market_nft_ownable.setCreatorFee(charlie, 200);
        assertEq(market_nft_ownable.fee_recipient(), charlie);
        // not creator cannot set creator
        vm.prank(alice);
        vm.expectRevert(bytes("Market: not creator"));
        market_nft_ownable.setCreatorFee(charlie, 200);
    }

    function testOwnerTransferReset() public {
        vm.startPrank(bob);
        nft_ownable.transferOwnership(charlie);
        vm.expectRevert(bytes("Market: not creator"));
        market_nft_ownable.setCreatorFee(charlie, 2);
        vm.stopPrank();
        vm.prank(charlie);
        market_nft_ownable.setCreatorFee(bob, 200);
        assertEq(market_nft_ownable.fee_recipient(), bob);
    }

    /** ------ FEE CALCULATION ----- */
    // bob is the creator; alice is the owner; charlie bids for alice's nft
    function testBidAcceptCreatorReceiveERC20() public {
        // set bob to be the creator fee recipient
        vm.prank(bob);
        market_nft_ownable.setCreatorFee(bob, 200); // 2% creator fee
        // mint an nft to alice
        nft_ownable.mintTo(alice);
        // charlie bids for the nft
        uint256 bidPrice = 1000;
        erc20.mint(charlie, uint256(1000));
        vm.prank(charlie);
        require(erc20.approve(address(market_nft_ownable), bidPrice));
        vm.prank(charlie);
        market_nft_ownable.buyerBid(1, bidPrice, address(erc20), uint32(1000));
        // alice accpets charlie's bid
        vm.startPrank(alice);
        nft_ownable.setApprovalForAll(address(market_nft_ownable), true);
        market_nft_ownable.sellerAcceptBid(1, charlie);
        vm.stopPrank();
        // test
        assertEq(erc20.balanceOf(alice), uint256(980)); // seller 
        assertEq(erc20.balanceOf(bob), uint256(20)); // fee recipient
        assertEq(erc20.balanceOf(charlie), uint256(0)); // buyer
        assertEq(nft_ownable.ownerOf(1), charlie); // new owner
    }

    // same as above except no creator setup 
    function testNoCreatorBidERC20() public {
        // set bob to be the creator fee recipient
        vm.prank(bob);
        // market_nft_ownable.setCreatorFee(bob, 200); // 2% creator fee
        // mint an nft to alice
        nft_ownable.mintTo(alice);
        // charlie bids for the nft
        uint256 bidPrice = 1000;
        erc20.mint(charlie, uint256(1000));
        vm.prank(charlie);
        require(erc20.approve(address(market_nft_ownable), bidPrice));
        vm.prank(charlie);
        market_nft_ownable.buyerBid(1, bidPrice, address(erc20), uint32(1000));
        // alice accpets charlie's bid
        vm.startPrank(alice);
        nft_ownable.setApprovalForAll(address(market_nft_ownable), true);
        market_nft_ownable.sellerAcceptBid(1, charlie);
        vm.stopPrank();
        // test
        assertEq(erc20.balanceOf(alice), uint256(1000)); // seller 
        assertEq(erc20.balanceOf(bob), uint256(0)); // fee recipient
        assertEq(erc20.balanceOf(charlie), uint256(0)); // buyer
        assertEq(nft_ownable.ownerOf(1), charlie); // new owner
    }

    // bob is the creator; alice is the owner who asks for a price; charlie is the acceptor and buyer
    function testAskAcceptCreatorReceiveETH() public {
        // set bob to be the creator fee recipient
        vm.prank(bob);
        market_nft_ownable.setCreatorFee(bob, 200); // 2% creator fee
        // mint an nft to alice
        nft_ownable.mintTo(alice);
        // alice asks for a price
        uint256 bidPrice = 1000; // in eth
        vm.startPrank(alice);
        nft_ownable.setApprovalForAll(address(market_nft_ownable), true);
        market_nft_ownable.sellerAsk(1, bidPrice, address(0), 1000);
        vm.stopPrank();
        // charlie accepts alice's ask
        vm.deal(charlie, bidPrice);
        vm.prank(charlie);
        market_nft_ownable.buyerAcceptAsk{value: bidPrice}(1, charlie);
        // test
        assertEq(alice.balance, uint256(980)); // seller
        assertEq(bob.balance, uint256(20)); // fee recipient
        assertEq(charlie.balance, uint256(0)); // buyer
        assertEq(nft_ownable.ownerOf(1), charlie); // new owner
    }

    // bob is the creator; alice is the owner who asks for a price; charlie is the acceptor and buyer
    function testNoCreatorAskETH() public {
        // set bob to be the creator fee recipient
        vm.prank(bob);
        // market_nft_ownable.setCreatorFee(bob, 200); // 2% creator fee
        // mint an nft to alice
        nft_ownable.mintTo(alice);
        // alice asks for a price
        uint256 bidPrice = 1000; // in eth
        vm.startPrank(alice);
        nft_ownable.setApprovalForAll(address(market_nft_ownable), true);
        market_nft_ownable.sellerAsk(1, bidPrice, address(0), 1000);
        vm.stopPrank();
        // charlie accepts alice's ask
        vm.deal(charlie, bidPrice);
        vm.prank(charlie);
        market_nft_ownable.buyerAcceptAsk{value: bidPrice}(1, charlie);
        // test
        assertEq(alice.balance, uint256(1000)); // seller
        assertEq(bob.balance, uint256(0)); // fee recipient
        assertEq(charlie.balance, uint256(0)); // buyer
        assertEq(nft_ownable.ownerOf(1), charlie); // new owner
    }

    //  same as above but with erc20 instead
    function testAskAcceptCreatorReceiveERC20() public {
        // set bob to be the creator fee recipient
        vm.prank(bob);
        market_nft_ownable.setCreatorFee(bob, 200); // 2% creator fee
        // mint an nft to alice
        nft_ownable.mintTo(alice);
        // alice asks for a price
        uint256 bidPrice = 1000; // in eth
        vm.startPrank(alice);
        nft_ownable.setApprovalForAll(address(market_nft_ownable), true);
        market_nft_ownable.sellerAsk(1, bidPrice, address(erc20), 1000);
        vm.stopPrank();
        // charlie accepts alice's ask
        erc20.mint(charlie, bidPrice);
        vm.prank(charlie);
        require(erc20.approve(address(market_nft_ownable), bidPrice));
        vm.prank(charlie);
        market_nft_ownable.buyerAcceptAsk(1, charlie);
        // test
        assertEq(erc20.balanceOf(alice), uint256(980)); // seller 
        assertEq(erc20.balanceOf(bob), uint256(20)); // fee recipient
        assertEq(erc20.balanceOf(charlie), uint256(0)); // buyer
        assertEq(nft_ownable.ownerOf(1), charlie); // new owner
    }

     //  same as above but with no creator setup
    function testNoCreatorERC20() public {
        // set bob to be the creator fee recipient
        vm.prank(bob);
        // market_nft_ownable.setCreatorFee(bob, 200); // 2% creator fee
        // mint an nft to alice
        nft_ownable.mintTo(alice);
        // alice asks for a price
        uint256 bidPrice = 1000; // in eth
        vm.startPrank(alice);
        nft_ownable.setApprovalForAll(address(market_nft_ownable), true);
        market_nft_ownable.sellerAsk(1, bidPrice, address(erc20), 1000);
        vm.stopPrank();
        // charlie accepts alice's ask
        erc20.mint(charlie, bidPrice);
        vm.prank(charlie);
        require(erc20.approve(address(market_nft_ownable), bidPrice));
        vm.prank(charlie);
        market_nft_ownable.buyerAcceptAsk(1, charlie);
        // test
        assertEq(erc20.balanceOf(alice), uint256(1000)); // seller 
        assertEq(erc20.balanceOf(bob), uint256(0)); // fee recipient
        assertEq(erc20.balanceOf(charlie), uint256(0)); // buyer
        assertEq(nft_ownable.ownerOf(1), charlie); // new owner
    }




}