pragma solidity ^0.8.13;

import "./Market.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IMarketFactory.sol";

// refer to UniswapV2Factory: https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol
contract MarketFactory is IMarketFactory {
    mapping(address => address) public getMarket;
    address[] public allMarkets;

    constructor() {
        // could setup fee recipient
    }

    function createMarket(address _nft) external returns (address market) {
        require(_nft != address(0), "Factory: zero address");
        require(getMarket[_nft] == address(0), "Factory: address exists");
        bytes memory bytecode = type(Market).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_nft));
        assembly {
            market := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IMarket(market).initialize(_nft); 
        getMarket[_nft] = market;
        allMarkets.push(market);
        emit MarketCreated(_nft, market, allMarkets.length);
    }
}