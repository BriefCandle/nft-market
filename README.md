# GAME (ongoing)
To better demonstrate the trading mechanisms as proposed, a crypto-game is made for fun. It is a 2048-style tile game where trading is part of the game experience. 

<!---
Game repo: https://github.com/BriefCandle/TILES-smart-contract

Game front-end (Goerli): https://tiles-angular.vercel.app/
-->


# UPCOMING CHANGES (to expand bidding strategies)
I am contemplating an update on what constitutes an offer. Previously, when submitting an offer (either bid or ask), a user stores three types of information: 1) token info (i.e., tokenId), 2) payment info (erc20 address and price), and 3) contract validity (duration). Now, if I expand token info, I can extending bidding strategies on the market. For example, 
```
struct TokenInfo = {
  uint256 tokenId;
  Traits[] traits; 
}
```
Then I can add a requirement for the NFT owner to accept bidder's bid: the NFT he owns must meet the TokenInfo the bidder submitted in his bid. For instance, if tokenId == 0, it means any NFT of the collection is covered by the bid. if there is an array of trait_type & trait_value specified, it means only NFT that meets the specified traits may be sold.

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


# SMART CONTRACT - Market

## MaketFactory.sol
Anyone might call the createMarket() function to create a market for an NFT project. The deployment cost is 1389559. 

## Market.sol
The Market consists of two independent components: 1) bid mechanism, 2) ask mechanism

### Bid-and-Accept
Payment of ANY ERC20 <--> ERC721

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
Payment of ETH or ANY ERC20 <--> ERC721

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
The creator of an NFT project may set up a creator fee and fee recipient as long as the NFT contract inheirts the Ownable standard. If the owner wants to split up fees among multiple contributors, he can deploy a fee-sharing multi-sig contract and submit this contract address as the recipient address. In the future, we could refer some of these peripheral contract templates into front-end for better ux. 

```setCreatorFee(address _fee_recipient, uint16 _percent) ```

Please be noted that "_percent" has two decimal points. Therefore, 10000 stands for 100.00%; 200 stands for 2.00%

### ERC20
The proposed protocol has no restriction over which ERC20 can be used as payment method. Therefore, any ERC20 can be offered as payment method as long as the offeror expects the acceptor to accept it.

## MarketTool.sol: Tools
(not completed)

The offer-and-acceptance mechanism is conceptually clear and implementation straightforward.

There are two pieces of information traders need to know before interacting with the market contracts: 1) NFT project address and 2) NFT tokenIds they would like to trade. For example, if they want to sweep the floor, they need to know which tokenIds have the lowest ask price. Front-end tools can be developed to help them locate the tokens considering on-chain looping would be too expensive. I made a batchOrder function

## MarketExtension.sol: Strategies
(not completed)

However, some strategies are not tokenId-based trades. For example, some buyers may bid for any tokenId for an NFT project as long as it trades below 1 ETH. It would become unreasonable to submit on-chain bids for all the ex., 9999 tokenIds. I use MarketExtension.sol to address this kind of offer-and-acceptance mechanism.
