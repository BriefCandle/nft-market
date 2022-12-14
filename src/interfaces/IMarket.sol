pragma solidity ^0.8.13;

interface  IMarket {

    struct AskInfo {
        uint256 tokenId;
        address seller;
        uint256 askPrice;
        address askERC20;
        uint256 timestamp;
        uint32 duration;
    }

    struct BidInfo {
        uint256 tokenId;
        address buyer;
        uint256 bidPrice;
        address bidERC20;
        uint256 timestamp;
        uint32 duration;
    }

    function getAsk(uint256 tokenId) external view returns (uint256, address, uint256, address, uint256, uint32);
    function getBid(uint256 tokenId, address bidder) external view returns (uint256, address, uint256, address, uint256, uint32);
    function getBidders(uint256 tokenId) external view returns(address[] memory);

    event BuyerBid(uint256 indexed tokenId, address buyer, uint256 bidPrice, address bidERC20, uint256 timestamp, uint32 duration);
    event BuyerRescindBid(uint256 indexed tokenId, address buyer);
    event SellerAcceptBid(uint256 indexed tokenId, address buyer, address seller, uint256 bidPrice, address bidERC20);

    function buyerBid(uint256 _tokenId, uint256 _bidPrice, address _bidERC20, uint32 _duration) external;
    function buyerRescindBid(uint256 _tokenId) external;
    function sellerAcceptBid(uint256 tokenId, address buyer) external;
    function checkBidBinding(uint256 tokenId, address buyer) external view returns (bool binding);


    event SellerAsk(uint256 indexed tokenId, address seller, uint256 askPrice, uint256 timestamp, uint32 duration);
    event SellerRescindAsk(uint256 indexed tokenId, address seller);
    event BuyerAcceptAsk(uint256 indexed tokenId, address seller, address buyer, uint256 askPrice);

    function sellerAsk(uint256 tokenId, uint256 askPrice, address askERC20, uint32 duration) external;
    function sellerRescindAsk(uint256 tokenId) external;
    function buyerAcceptAsk(uint256 tokenId, address to) external payable;
    function checkAskBinding(uint256 tokenId) external view returns (bool binding);


    function initialize(address _nft) external;
    function setCreatorFee(address _fee_recipient, uint16 _percent) external; 

    event SetCreatorFee(address _fee_recipient, uint16 _percent);
}