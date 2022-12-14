pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// probably need to store them into MarketFactory to create unique MarketExtension for each NFT market
contract MarketExtension {

    event BuyerFloorBid(address bidder, uint256 bidPrice, address bidERC20, uint256 timestamp, uint32 duration);
    event SellerAcceptFloorBid(uint256 tokenId, address bidder, address seller, uint256 bitPrice, address bidERC20);

    address nft;
    address market;

    struct FloorBidInfo {
        address bidder;
        uint256 bidPrice;
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

    // before calling this function, buyer must call ERC20.approve()
    function buyerFloorBid(uint256 bidPrice, address bidERC20, uint32 duration) external {
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

    // before calling this function, seller must call nft.setApprovalForAll()
    function sellerAcceptFloorBid(uint256 tokenId, address _bidder) external {
        require(msg.sender == IERC721(nft).ownerOf(tokenId), "Market: not owner");
        FloorBidInfo memory floorBidInfo = getFloorBid[_bidder];
        require((block.timestamp - floorBidInfo.timestamp) <= floorBidInfo.duration, "Market: not bid or bid has expired"); //this implicitly requires there is an bid
        delete getFloorBid[_bidder];
        IERC721(nft).safeTransferFrom(msg.sender, floorBidInfo.bidder, tokenId, "");
        require(IERC20(floorBidInfo.bidERC20).transferFrom(floorBidInfo.bidder, msg.sender, floorBidInfo.bidPrice), "Market: ERC20 transfer fail");
        emit SellerAcceptFloorBid(tokenId, _bidder, msg.sender, floorBidInfo.bidPrice, floorBidInfo.bidERC20);
    }

    function _removeBidderFromArray(address buyer) private {
        for (uint i = 0; i < floorBidderList.length; i++) {
            if (floorBidderList[i] == buyer) {
                floorBidderList[i] = floorBidderList[floorBidderList.length-1];
                floorBidderList.pop();
                return;
            }
        }
        revert("Market: no bid");
    }


    function buyerRescindFloorBid() external {}

}