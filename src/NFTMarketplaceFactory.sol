pragma solidity ^0.8.13;

import "./NFTMarketplace.sol";
import "./interfaces/INFTMarketplace.sol";

// refer to UniswapV2Factory: https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol
contract NFTMarketplaceFactory {
    mapping(address => address) public getMarketplace;
    address[] public allMarketplaces;

    event MarketPlaceCreated(address indexed _nft, address marketplace, uint);

    constructor() {
        // could setup fee recipient
    }

    function createMarketplace(address _nft) external returns (address marketplace) {
        require(_nft != address(0), "zero address");
        require(getMarketplace[_nft] == address(0), "address exists");
        bytes memory bytecode = type(NFTMarketplace).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_nft));
        assembly {
            marketplace := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        INFTMarketplace(marketplace).initialize(_nft); // could get owner if Ownable
        getMarketplace[_nft] = marketplace;
        allMarketplaces.push(marketplace);
        emit MarketPlaceCreated(_nft, marketplace, allMarketplaces.length);

    }
}