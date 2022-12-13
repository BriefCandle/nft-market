pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// probably need to store them into MarketFactory to create unique MarketExtension for each NFT market
contract MarketExtension {

    event BuyerFloorBid(address bidder, uint64 bidPrice, address bidERC20, uint256 timestamp, uint32 duration);

    address nft;
    address market;

    struct FloorBidInfo {
        address bidder;
        uint64 bidPrice;
        address bidERC20;
        uint256 timestamp;
        uint32 duration;
    }

    mapping(address => FloorBidInfo) public getFloorBid;
    address[] floorBidderList;

    constructor(address _nft, address _market) {
        nft = _nft;
        market = _market;
    }

    function buyerFloorBid(uint64 bidPrice, address bidERC20, uint32 duration) external {
        require(IERC20(bidERC20).allowance(msg.sender, address(this)) >= bidPrice, "Market: not approved");
        if (getFloorBid[msg.sender].bidder == address(0)) floorBidderList.push(msg.sender);
        getFloorBid[msg.sender] = FloorBidInfo({
            bidder: msg.sender,
            bidPrice: bidPrice,
            bidERC20: bidERC20,
            timestamp: block.timestamp,
            duration: duration
        });
        emit BuyerFloorBid(msg.sender, bidPrice, bidERC20, block.timestamp, duration);
    }

    function sellerAcceptFloorBid(uint256 tokenId, address bidder) external {}
}