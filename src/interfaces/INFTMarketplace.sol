pragma solidity ^0.8.13;

interface  INFTMarketplace {
    event BuyerBid(uint256 indexed tokenId, address buyer, uint64 bidPrice, address bidERC20, uint256 timestamp, uint32 duration);
    event BuyerCancelBid(uint256 indexed tokenId, address buyer);
    event SellerAcceptBid(uint256 indexed tokenId, address buyer, address seller, uint64 bidPrice, address bidERC20);

    function buyerBid(uint256 _tokenId, uint64 _bidPrice, address _bidERC20, uint32 _duration) external;
    function buyerCancelBid(uint256 _tokenId) external;
    function sellerAcceptBid(uint256 tokenId, address buyer) external;
    function checkBidBinding(uint256 tokenId, address buyer) external view returns (bool binding);

    event SellerAsk(uint256 indexed tokenId, address seller, uint64 askPrice, uint256 timestamp, uint32 duration);
    event SellerCancelAsk(uint256 indexed tokenId, address seller);
    event BuyerAcceptAsk(uint256 indexed tokenId, address seller, address buyer, uint64 askPrice);

    function sellerAsk(uint256 tokenId, uint64 askPrice, uint32 duration) external;
    function sellerCancelAsk(uint256 tokenId) external;
    function buyerAcceptAsk(uint256 tokenId) external payable;
    function checkAskBinding(uint256 tokenId) external view returns (bool binding);

    function initialize(address _nft) external;
}