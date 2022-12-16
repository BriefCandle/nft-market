pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMarket.sol";

contract Market is IMarket{
    
    address public factory;
    address public nft;

    // creator fee setup
    address public fee_recipient;
    uint16 public fee_percent; // two points decimal, max 10000, ex., 250 -> 2.5%

    mapping(uint256 => AskInfo) public getAsk;
    mapping(uint256 => mapping(address => BidInfo)) public getBid;
    mapping(uint256 => address[]) public bidderList;

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _nft) external {
        require(msg.sender == factory);
        nft = _nft;
    }

    // read nft owner address from nft address if there is an owner() method
    function setCreatorFee(address _fee_recipient, uint16 _percent) public {
        (bool success, bytes memory returnData) = nft.staticcall(
            abi.encodeWithSelector(bytes4(keccak256("owner()")))
        );
        require(success, "Market: no creator setup");
        address _owner = abi.decode(returnData, (address));
        require(msg.sender == _owner, "Market: not creator");
        require(_percent <= 10000, "Market: fee_percent too high");
        fee_percent = _percent;
        fee_recipient = _fee_recipient;
    }

    /** ------- BID MECHANISM ------- */
    // before calling this function, seller must call erc20.approve()
    function buyerBid(uint256 tokenId, uint256 bidPrice, address bidERC20, uint32 duration) external {
        require(IERC20(bidERC20).allowance(msg.sender, address(this)) >= bidPrice, "Market: not approved");
        if (getBid[tokenId][msg.sender].buyer == address(0)) bidderList[tokenId].push(msg.sender);
        getBid[tokenId][msg.sender] = BidInfo({
            tokenId: tokenId,
            buyer: msg.sender,
            bidPrice: bidPrice,
            bidERC20: bidERC20,
            timestamp: block.timestamp,
            duration: duration
        });

        emit BuyerBid(tokenId, msg.sender, bidPrice, bidERC20, block.timestamp, duration);
    }

    function buyerRescindBid(uint256 tokenId) external {
        _removeBidderFromArray(tokenId, msg.sender);
        delete getBid[tokenId][msg.sender];
        emit BuyerRescindBid(tokenId, msg.sender);
    }

    function _removeBidderFromArray(uint256 tokenId, address _bidder) private {
        address[] storage bidders = bidderList[tokenId];
        for (uint i = 0; i < bidders.length; i++) {
            if (bidders[i] == _bidder) {
                bidders[i] = bidders[bidders.length-1];
                bidders.pop();
                return;
            }
        }
        revert("Market: no bid");
    }

    // before calling this function, seller must call nft.setApprovalForAll()
    function sellerAcceptBid(uint256 tokenId, address _bidder) external {
        require(msg.sender == IERC721(nft).ownerOf(tokenId), "Market: not owner");
        BidInfo memory bidInfo = getBid[tokenId][_bidder];
        require((block.timestamp - bidInfo.timestamp) <= bidInfo.duration, "Market: not bid or bid has expired"); //this implicitly requires there is an bid
        _removeBidderFromArray(tokenId, _bidder);
        delete getBid[tokenId][_bidder];
        IERC721(nft).safeTransferFrom(msg.sender, bidInfo.buyer, tokenId, "");
        // transfer ERC20 to respective recipients
        if (fee_recipient != address(0)) {
            require(IERC20(bidInfo.bidERC20).transferFrom(bidInfo.buyer, msg.sender, bidInfo.bidPrice*(10000-fee_percent)/10000), "Market: ERC20 transfer fail");
            require(IERC20(bidInfo.bidERC20).transferFrom(bidInfo.buyer, fee_recipient, bidInfo.bidPrice*fee_percent/10000), "Market: ERC20 transfer fail");
        } else {
            require(IERC20(bidInfo.bidERC20).transferFrom(bidInfo.buyer, msg.sender, bidInfo.bidPrice), "Market: ERC20 transfer fail");

        }
        
        emit SellerAcceptBid(tokenId, _bidder, msg.sender, bidInfo.bidPrice, bidInfo.bidERC20);
    }

    function checkBidBinding(uint256 tokenId, address _bidder) public view returns (bool binding) {
        BidInfo memory bidInfo = getBid[tokenId][_bidder];
        binding = (block.timestamp - bidInfo.timestamp) <= bidInfo.duration && 
        IERC20(bidInfo.bidERC20).allowance(bidInfo.buyer, address(this)) >= bidInfo.bidPrice && 
        IERC20(bidInfo.bidERC20).balanceOf(bidInfo.buyer) >= bidInfo.bidPrice ? true : false;
    }

    function getBidders(uint256 tokenId) public view returns(address[] memory) {
        return bidderList[tokenId];
    }


    /** ------- ASK MECHANISM ------- */
    // before calling this function, seller must call nft.setApprovalForAll()
    // askERC20 == address(0) means using eth as payment
    function sellerAsk(uint256 tokenId, uint256 askPrice, address askERC20, uint32 duration) external {
        require(IERC721(nft).isApprovedForAll(msg.sender, address(this)) == true, "Market: not approved");
        require(msg.sender == IERC721(nft).ownerOf(tokenId), "Market: not owner"); //ownerOf() require tokenId exists
        getAsk[tokenId] = AskInfo({
            tokenId: tokenId,
            seller: msg.sender,
            askPrice: askPrice,
            askERC20: askERC20,
            timestamp: block.timestamp,
            duration: duration
        });

        emit SellerAsk(tokenId, msg.sender, askPrice, askERC20, block.timestamp, duration);
    }

    function sellerRescindAsk(uint256 tokenId) external {
        require(msg.sender == IERC721(nft).ownerOf(tokenId), "Market: not owner"); 
        delete getAsk[tokenId]; 

        emit SellerRescindAsk(tokenId, msg.sender);
    }

    // before calling this function, seller must call erc20.approve() for address to if buyer is asking for erc20
    function buyerAcceptAsk(uint256 tokenId, address to) external payable{
        AskInfo memory askInfo = getAsk[tokenId];
        require((block.timestamp - askInfo.timestamp) <= askInfo.duration, "Market: no ask or ask has expired"); //this implicitly requires there is an ask
        require(IERC721(nft).ownerOf(tokenId) == askInfo.seller, "Market: owner has changed"); 
        if (askInfo.askERC20 == address(0)) { // paying with eth
            require(msg.value == askInfo.askPrice, "Market: payment not enough");
            delete getAsk[tokenId];
            if (fee_recipient != address(0)) {
                (bool sent, ) = askInfo.seller.call{value: msg.value*(10000-fee_percent)/10000}("");
                require(sent, "Market: Failed to send Ether");
                (sent, ) = fee_recipient.call{value: msg.value*fee_percent/10000}("");
                require(sent, "Market: Failed to send Ether");
            } else {
                (bool sent, ) = askInfo.seller.call{value: msg.value}("");
                require(sent, "Market: Failed to send Ether");
            }
        } else {
            if (fee_recipient != address(0)) {
                require(IERC20(askInfo.askERC20).transferFrom(to, askInfo.seller, askInfo.askPrice*(10000-fee_percent)/10000), "Market: ERC20 transfer fail");
                require(IERC20(askInfo.askERC20).transferFrom(to, fee_recipient, askInfo.askPrice*fee_percent/10000), "Market: ERC20 transfer fail");
            } else {
                require(IERC20(askInfo.askERC20).transferFrom(to, askInfo.seller, askInfo.askPrice), "Market: ERC20 transfer fail");
            }
        }
        IERC721(nft).safeTransferFrom(askInfo.seller, to, tokenId, "");

        emit BuyerAcceptAsk(tokenId, askInfo.seller, to, askInfo.askPrice);
    }

    function checkAskBinding(uint256 tokenId) public view returns (bool binding) {
        AskInfo memory askInfo = getAsk[tokenId];
        binding = (block.timestamp - askInfo.timestamp) <= askInfo.duration && 
        IERC721(nft).isApprovedForAll(IERC721(nft).ownerOf(tokenId), address(this)) &&
        IERC721(nft).ownerOf(tokenId) == askInfo.seller ? true : false;
    }

}