pragma solidity ^0.8.13;

import "./interfaces/IMarketFactory.sol";
import "./interfaces/IMarket.sol";

contract MarketTool {

    address factory;

    constructor(address _factory) {
       factory = _factory;
    }


    // buyer purchases a batch of sellers' asks
    // buyer needs to first use an api, ex., alchemy, to get all the desired tokenIds
    // otherwise, it is too expensive to query it on-chain
    function batchPurchase(address _nft, uint256[] calldata batchOrders) payable external {
        address market = IMarketFactory(factory).getMarket(_nft);
        for (uint i = 0; i < batchOrders.length; i++) {
            uint256 tokenId = batchOrders[i];
            if (IMarket(market).checkAskBinding(tokenId) == true) {
                (, , uint256 askPrice, , , ) = IMarket(market).getAsk(tokenId);
                IMarket(market).buyerAcceptAsk{value: askPrice}(tokenId, msg.sender);
            }
        }
    }

    // function batch

    // sweep the floor
    // accept the lowest ask of a collection
    // pass in the nft contract address
    // get marketplace address
    // go through all asks's price and accept the lowest bids until it reaches budget
    // function sweepFloor(address _nft, uint256 max_token) public {
    //     // find the market
    //     address market = IMarketFactory(factory).getMarket(_nft);
    //     //  
    //     // IMarket(market).getAsk
    // }

    

}