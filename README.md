# nft-marketplace
This is a testing project to try on different marketplace setup.

I will first try the very common nft marketplace setup used by many projects. Buyer and seller needs to submit bid or ask of an marketplace item, and then wait for the counter party to accept. A marketplace contract will be used to handle the order, but seller must first call approveForAll.

However, instead of having a universal marketplace for all nfts, I would like to use a factory to generate nft marketplace for each nft. Or better, make an nft contract to inherit an abstract marketplace contract so that said nft can have a built-in marketplace just like cryptopunkmarket.

Then, based on these rudimental mechanisms, I would like to implement some trading strategies, such as floor-sweeping, and etc. 

In the meantime, I would like to explore these popular protocols, such as seaport and x2y2, and understand their proxy contract.

In the end, I would like to try to 