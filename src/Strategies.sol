pragma solidity ^0.8.13;
import "./interfaces/IMarketFactory.sol";

contract Strategies {

    address factory;

    constructor(address _factory) {
       factory = _factory;
    }

    // sweep the floor
    // accept the lowest ask of a collection
    // pass in the nft contract address
    // get marketplace address
    // go through all asks's price and accept the lowest bids until it reaches budget
    function sweepFloor(address _nft) public {
         address market = IMarketFactory(factory).getMarket(_nft);
    }

}