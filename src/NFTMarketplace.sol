pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/INFTMarketplace.sol";

contract NFTMarketplace is INFTMarketplace{
    
    address factory;
    address nft;
    // address owner;
    // address feeRecipient;

    struct BidInfo {
        uint256 tokenId;
        address buyer;
        uint64 bidPrice;
        address bidERC20;
        uint256 timestamp;
        uint32 duration;
    }

    struct AskInfo {
        uint256 tokenId;
        address seller;
        uint64 askPrice;
        uint256 timestamp;
        uint32 duration;
    }

    mapping(uint256 => AskInfo) public askList;
    mapping(uint256 => mapping(address => BidInfo)) public bidList;
    mapping(uint256 => address[]) public bidderList;

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _nft) external {
        require(msg.sender == factory);
        nft = _nft;
    }

    /** ------- BID MECHANISM ------- */
    // before calling this function, seller must call erc20.approve()
    function buyerBid(uint256 tokenId, uint64 bidPrice, address bidERC20, uint32 duration) external {
        require(IERC20(bidERC20).allowance(msg.sender, address(this)) >= bidPrice, "not approved");
        if (bidList[tokenId][msg.sender].buyer == address(0)) bidderList[tokenId].push(msg.sender);
        bidList[tokenId][msg.sender] = BidInfo({
            tokenId: tokenId,
            buyer: msg.sender,
            bidPrice: bidPrice,
            bidERC20: bidERC20,
            timestamp: block.timestamp,
            duration: duration
        });
        emit BuyerBid(tokenId, msg.sender, bidPrice, bidERC20, block.timestamp, duration);
    }

    function buyerCancelBid(uint256 tokenId) external {
        _removeBidderFromArray(tokenId, msg.sender);
        delete bidList[tokenId][msg.sender];
        emit BuyerCancelBid(tokenId, msg.sender);
    }

    function _removeBidderFromArray(uint256 tokenId, address buyer) private {
        address[] storage bidders = bidderList[tokenId];
        for (uint i = 0; i < bidders.length; i++) {
            if (bidders[i] == buyer) {
                bidders[i] = bidders[bidders.length-1];
                bidders.pop();
                return;
            }
        }
        revert("no bid");
    }

    // before calling this function, seller must call nft.setApprovalForAll()
    function sellerAcceptBid(uint256 tokenId, address buyer) external {
        require(msg.sender == IERC721(nft).ownerOf(tokenId), "not owner");
        BidInfo memory bidInfo = bidList[tokenId][buyer];
        require((block.timestamp - bidInfo.timestamp) <= bidInfo.duration, "not bid or bid has expired"); //this implicitly requires there is an bid
        _removeBidderFromArray(tokenId, buyer);
        delete bidList[tokenId][buyer];
        IERC721(nft).safeTransferFrom(msg.sender, bidInfo.buyer, tokenId, "");
        require(IERC20(bidInfo.bidERC20).transferFrom(bidInfo.buyer, msg.sender, bidInfo.bidPrice), "ERC20 transfer fail");
        emit SellerAcceptBid(tokenId, buyer, msg.sender, bidInfo.bidPrice, bidInfo.bidERC20);
    }

    function checkBidBinding(uint256 tokenId, address buyer) public view returns (bool binding) {
        BidInfo memory bidInfo = bidList[tokenId][buyer];
        binding = (block.timestamp - bidInfo.timestamp) <= bidInfo.duration && 
        IERC20(bidInfo.bidERC20).allowance(bidInfo.buyer, address(this)) >= bidInfo.bidPrice ? true : false;
    }

    function getBidders(uint256 tokenId) public view returns(address[] memory) {
        return bidderList[tokenId];
    }


    /** ------- ASK MECHANISM ------- */
    // before calling this function, seller must call nft.setApprovalForAll()
    function sellerAsk(uint256 tokenId, uint64 askPrice, uint32 duration) external {
        require(IERC721(nft).isApprovedForAll(msg.sender, address(this)) == true, "not approved");
        require(msg.sender == IERC721(nft).ownerOf(tokenId), "not owner"); //ownerOf() require tokenId exists
        askList[tokenId] = AskInfo({
            tokenId: tokenId,
            seller: msg.sender,
            askPrice: askPrice,
            timestamp: block.timestamp,
            duration: duration
        });
        emit SellerAsk(tokenId, msg.sender, askPrice, block.timestamp, duration);
    }

    function sellerCancelAsk(uint256 tokenId) external {
        require(msg.sender == IERC721(nft).ownerOf(tokenId), "not owner"); 
        delete askList[tokenId]; 
        emit SellerCancelAsk(tokenId, msg.sender);
    }

    function buyerAcceptAsk(uint256 tokenId) external payable{
        AskInfo memory askInfo = askList[tokenId];
        require((block.timestamp - askInfo.timestamp) <= askInfo.duration, "no ask or ask has expired"); //this implicitly requires there is an ask
        require(IERC721(nft).ownerOf(tokenId) == askInfo.seller, "owner has changed"); 
        require(msg.value == askInfo.askPrice, "payment not enough");
        delete askList[tokenId];
        (bool sent, ) = askInfo.seller.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        IERC721(nft).safeTransferFrom(askInfo.seller, msg.sender, tokenId, "");
        emit BuyerAcceptAsk(tokenId, askInfo.seller, msg.sender, askInfo.askPrice);
    }

    function checkAskBinding(uint256 tokenId) public view returns (bool binding) {
        AskInfo memory askInfo = askList[tokenId];
        binding = (block.timestamp - askInfo.timestamp) <= askInfo.duration && 
        IERC721(nft).isApprovedForAll(IERC721(nft).ownerOf(tokenId), address(this)) &&
        IERC721(nft).ownerOf(tokenId) == askInfo.seller ? true : false;
    }

    function getAskList() public view { }


}