# OVERVIEW
The Market is based on an offer-and-accept mechanism automating the transfer of considerations of ERC721, ERC20 & ETH between buyers and sellers of NFTs. It follows the uniswap-factory pattern and consists of two componenets: 1) MarketFactory, 2) Market.

Each NFT project has its own Market for traders to trade on, which is created and initialized by MarketFactory. Developers and project creators are welcomed to examine the code, setup the creator fee, and adopt it for their own usage. 

<!-- Currently, the proof-of-concept MarketFactory contract is running on Goerli Testnet. Feel free to interact with the smart contracts:  -->

<!-- In the future, governance tokens could be issued to incentivize adoption and on-chain governance.  -->

### Offer-And-Accept 
Each sale agreement consists of two parties: 1) buyer and 2) seller, and three componenets: 1) offer, 2) consideration, and 3) acceptance. Depending on which party makes the offer first, sale of goods are to be categorized into two groups: 1) bid if buyer offers, 2) ask if seller offers. 

Once an offer is made (be it bid or ask), the counter-party can accept it to complete the sale of goods.

Uniswap revolutionizes ERC20 trading, but sale of NFT still follows the offer-and-acceptance mechanism because NFT by nature is non-fungible. 

We made the Market responsible of lodging bids & asks, displaying them as offers, and directing the transfer of considerations between buyers and sellers upon acceptance.

### Binding Offer
In traditional business practice, an offer is sometimes NOT binding to the offeror. Blockchains revolutionize contract formation and realization. With on-chain data and authorizations, traders can easily check whether the offers (be it bids or asks) are valid and binding. Once offer is found to be binding on-chain, the acceptor can call the acceptance transaction on the offer to complete the sale of goods. 

Offer is valid when the offeror hasn't revoked his offer && when the offer duration has not elapsed. 

Offer is binding when the offerer has not revoke the authorization given to the Market to operate his consideration (i.e., ERC20 for bidder & ERC721 for asker) && when the offerer still possess the required consideration as specified in his offer (i.e., amount of ERC20 for bidder & ownership of ERC721 for asker).


# SMART CONTRACT

## MaketFactory.sol
Anyone might call the createMarket() function to create a market for an NFT project. The deployment cost is 1389559. 

## Market.sol
The Market consists of two independent components: 1) bid mechanism, 2) ask mechanism

### Bid-and-Accept
Payment of ERC20 <--> ERC721

1) ```buyerBid(uint256 tokenId, uint64 bidPrice, address bidERC20, uint32 duration)```
Anyonce wanting to buy an NFT can offer a bid as long as he specifies tokenId, bid price, ERC20 token he'd like to use as payment, and the duration for the offer to be valid. Please be noted that buyer needs to authorize the Market as the operator of the ERC20 token beforehand.

2) ```buyerRescindBid(uint256 tokenId)```
Anyone can rescind his previouly offered bid for a tokenId.

3) ```sellerAcceptBid(uint256 tokenId, address buyer)```
The owner of the NFT tokenId can accept any bid make to his NFT so as to complete the sale of his NFT. Please be noted that seller needs to authorize the Market as the operator of the ERC721 token beforehand.

4) ```checkBidBinding(uint256 tokenId, address buyer)```
Anyone can check whether a bid is currently binding on the buyer. This on-chain view method provides composibiliy for later on-chain adoption.


| Transaction | Gas Usage| Transaction Fee (assuming 12.7Gwei gas price) |    
| :---: | :---: | :---: | 
| ERC20 approve() | 24646 | 0.000314 ETH |
| ERC721 setApprovalForAll() | 24672 | 0.000314 ETH |
| buyerBid() (first bid) | 157585 | 0.002 ETH |
| buyerBid() (subsequent bid) | 3512 | 0.0000447 ETH |
| buyerRescindBid | 2741 | 0.0000349 ETH |
| sellerAcceptBid() | 60462 | 0.000771 ETH

The overal transaction cost for a seller to sell an NFT is 0.000771 ETH.

### Ask-and-Accept
Payment of ETH <--> ERC721

1) ```sellerAsk(uint256 tokenId, uint64 askPrice, uint32 duration)```
The owner of the NFT tokenId wanting to sell it can offer an ask. Please be noted that seller needs to authorize the Market as the operator of the ERC721 token beforehand.

2) ```sellerRescindAsk(uint256 tokenId)```
Seller can rescind the previously offered ask as long as he is still the owner of the NFT token.

3) ```buyerAcceptAsk(uint256 tokenId)```
Anyone wanting to buy the NFT can accept seller's offered ask as long as he is paying the amount of ETH required by seller. 

4) ```function checkAskBinding(uint256 tokenId)```
Anyone can check whether an ask is currently binding on the seller. This on-chain view method provides composibiliy for later on-chain adoption.


| Transaction | Gas Usage | Transaction Fee (assuming 12.7Gwei gas price) |  
| :---: | :---: | :---: | 
| ERC721 setApprovalForAll() | 24672 | 0.000314 ETH |
| sellerAsk() | 95820 | 0.00122 ETH | 
| sellerRescindAsk() | 3368 | 0.0000429 ETH |
| buyerAcceptAsk() | 60454 | 0.000770 ETH |

The overal transaction cost for a buyer to purchase an NFT is 0.000770 ETH.

### Creator Fee
Any NFT contract adopting the ERC721 and Ownable standards could set up creator fee and recipient address for its project owner. If the owner wants to split up fees among multiple contributors, he can deploy a fee-sharing multi-sig contract and submit this contract address as the recipient address. In the future, we could refer some of these peripheral contract templates into front-end for better ux. 


## Strategy
Buying and selling methods can be built on top of the core bid/ask mechanisms
### Seller accept the highest bid

### Buyer accept the lowest offer from an NFT collection
