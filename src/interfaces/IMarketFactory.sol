pragma solidity ^0.8.13;

interface  IMarketFactory {
    event MarketCreated(address indexed _nft, address market, uint);

    function getMarket(address nft) external view returns (address market);
    function allMarkets(uint) external view returns (address market);
    function createMarket(address _nft) external returns (address market);
}