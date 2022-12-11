# OVERVIEW
The Marketplace is based on an offer-and-accept mechanism directing transfer of considerations of ERC721, ERC20 & ETH between buyers and sellers of NFTs. It follows the uniswap-factory pattern and consists of two componenets: 1) MarketplaceFactory, 2) Marketplace.

Each NFT project has its own Marketplace for traders to trade on, which is created and initialized by MarketplaceFactory. Developers and project creators are welcomed to examine the code, setup the creator fee, and adopt it for their own usage. 

Currently, the proof-of-concept MarketplaceFactory contract is running on Goerli Testnet. Feel free to interact with the smart contracts: 

<!-- In the future, governance tokens could be issued to incentivize adoption and on-chain governance.  -->

## Offer-And-Accept 
Each sale agreement consists of two parties: 1) buyer and 2) seller, and three componenets: 1) offer, 2) consideration, and 3) acceptance. Depending on which party makes the offer first, sale of goods are to be categorized into two groups: 1) bid if buyer offers, 2) ask if seller offers. 

Once an offer is made (be it bid or ask), the counter-party can accept it to complete the sale of goods.

Uniswap revolutionizes ERC20 trading, but sale of NFT still follows the offer-and-acceptance mechanism because NFT by nature is non-fungible. 

We made the Marketplace simply responsible of lodging bids & asks, displaying them as offers, and directing the transfer of considerations between buyers and sellers upon acceptance.

## Binding Offer
In traditional business practice, although acceptance could be immediately binding to the acceptor, an offer is sometimes NOT binding to the offeror contract completion. Traders can easily check whether the offers, bids or asks, are valid and binding. Once offer is found to be binding on-chain, the acceptor can call the acceptance transaction on the offer to complete the sale of goods. 

Offer is valid when the offeror hasn't revoked his offer && when the offer duration has not elapsed. 

Offer is binding when the offerer has not revoke the authorization given to the Marketplace to operate his consideration (i.e., ERC20 for bidder & ERC721 for asker) && when the offerer still possess the required consideration as specified in his offer (i.e., amount of ERC20 for bidder & ownership of ERC721 for asker).

The Marketplace provides two methods to check:
- function checkBidBinding(uint256 tokenId, address buyer) public view returns (bool binding)
- function checkAskBinding(uint256 tokenId) public view returns (bool binding)

## MaketplaceFactory
Anyone might call the createMarketplace() function to create a marketplace for an NFT project. The deployment cost is 1389559. 

## Marketplace
The Marketplace consists of two independent components: 1) bid mechanism, 2) ask mechanism

## Bid-and-Accept


## Ask-and Accept


## Creator Fee
Any NFT contract adopting the ERC721 and Ownable standards could set up creator fee and recipient address for its project owner. If the owner wants to split up fees among multiple contributors, he can deploy a fee-sharing multi-sig contract and submit this contract address as the recipient address. In the future, we could refer some of these peripheral contract templates into front-end for better ux. 

## Strategy
Buying and selling methods can be built on top of the core bid/ask mechanisms
### Seller accept the highest bid

### Buyer accept the lowest offer from an NFT collection
