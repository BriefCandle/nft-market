// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import 'src/NFT.sol';

// contract NFTTest is Test {
//     NFT nft;

//     function setUp() public {
//       nft = new NFT("a","b");
//     }

//     function test1() public {
//         assertEq(
//             hello.greet(),
//             "Foundry is fast!"
//         );
//     }

//     function test2() public {
//         assertEq(hello.version(), 0);
//         hello.updateGreeting("Hello World");
//         assertEq(hello.version(), 1);
//         string memory value = hello.greet();
//         emit log(value);
//         assertEq(
//             hello.greet(),
//             "Hello World"
//         );
//     }

//     function test3(string memory _greeting) public {
//     assertEq(hello.version(), 0);
//     hello.updateGreeting(_greeting);
//     assertEq(hello.version(), 1);
//     assertEq(
//         hello.greet(),
//         _greeting
//     );
// }
// }