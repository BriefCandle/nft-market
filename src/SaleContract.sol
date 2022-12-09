pragma solidity ^0.8.0;

// import "solmate/tokens/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

abstract contract SaleContract is ERC721 {
    struct AskInfo {
        uint256 tokenId;
        address seller;
        uint64 askPrice;
        uint256 timestamp;
        uint32 duration;
    }

    mapping(uint256 => AskInfo) public askList;

    // can later extend a function to allow approved operator to ask
    // for now, only owner may ask to sell
    function sellerAsk(uint256 tokenId, uint64 askPrice, uint32 duration) public {
        require(msg.sender == ownerOf(tokenId), "not owner"); //ownerOf() itself require tokenId exists
        askList[tokenId] = AskInfo({
            tokenId: tokenId,
            seller: msg.sender,
            askPrice: askPrice,
            timestamp: block.timestamp,
            duration: duration
        });
    }

    function sellerCancelAsk(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "not owner"); 
        delete askList[tokenId]; 
    }

    function buyerAcceptAsk(uint256 tokenId) public payable{
        AskInfo memory askInfo = askList[tokenId];
        // require duration has not passed => ask is valid
        require((block.timestamp - askInfo.timestamp) <= askInfo.duration, "ask has expired, rendering ask invalid"); //this implicitly requires there is an ask
        // require seller must still be owner in case nft is transferred to new owner
        require(ownerOf(tokenId) == askInfo.seller, "owner has changed, rendering ask invalid");
        // requires buyer has the required askPrice
        require(msg.value == askInfo.askPrice, "payment not enough");
        // delete ask info
        delete askList[tokenId];
        // send over eth to owner/seller
        (bool sent, ) = askInfo.seller.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        // transfer nft to buyer by bypassing _isApprovedOrOwner
        _safeTransfer(askInfo.seller, msg.sender, tokenId, "");
    }

    function getAskList() public view { }

    
}