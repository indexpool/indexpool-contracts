import {expect} from "chai";
import {ethers} from "hardhat";
import constants from "../constants";
import fetch from 'node-fetch';

describe("KyberLiquidityBridge", function () {
    let owner;
    let other;
    let kyberSwapBridge;
    let kyberLiquidityBridge;
    let wmaticBridge;
    let wallet;

    const TOKENS = constants['POLYGON']['TOKENS'];

    beforeEach(async function () {
        // Get 2 signers to enable to test for permission rights
        [owner, other] = await ethers.getSigners();

        // Instantiate Quickswap bridge
        let KyberSwapBridge = await ethers.getContractFactory("KyberSwapBridge");
        kyberSwapBridge = await KyberSwapBridge.deploy();

        let KyberLiquidityBridge = await ethers.getContractFactory("KyberLiquidityBridge");
        kyberLiquidityBridge = await KyberLiquidityBridge.deploy();

        let WMaticBridge = await ethers.getContractFactory("WMaticWrapBridge");
        wmaticBridge = await WMaticBridge.deploy();

        // Instantiate Wallet
        let Wallet = await ethers.getContractFactory("Wallet");
        wallet = await Wallet.deploy();
    });

    describe("Actions", function () {
        it("Add Liquidity with MATIC + KNC", async function () {
            // Set bridges addresses
            var _bridgeAddresses = [
                wmaticBridge.address,
                kyberSwapBridge.address,
            ];

            // Get response from 0x API
            let buyToken = TOKENS['KNC'];
            let sellToken = TOKENS['WMAIN'];
            let sellAmount = '1000000000000000000';

            let req_0x = await fetch(`https://polygon.api.0x.org/swap/v1/quote?buyToken=${buyToken}&sellToken=${sellToken}&sellAmount=${sellAmount}&includedSources=KyberDMM`);
            let data_0x = await req_0x.json();

            console.log(data_0x.orders[0].fillData)

            let tokenAddressPath = data_0x.orders[0].fillData.tokenAddressPath;
            let poolsPath = data_0x.orders[0].fillData.poolsPath;
            let poolAddress = '0x37e6449b0e99befd2a708ea048d970f4ff4dc65d';


            console.log( [
                [buyToken, sellToken], // address[] tokens,
                poolAddress,
                [100_000, 100_000], // percentages
                [1, 1],  // minAmounts,
                [0, 0], // vReserveRatioBounds
            ],)

            // Set encoded calls
            var _bridgeEncodedCalls = [
                wmaticBridge.interface.encodeFunctionData(
                    "wrap",
                    [
                        100_000
                    ],
                ),
                kyberSwapBridge.interface.encodeFunctionData(
                    "swapTokenToToken",
                    [
                        50_000, // uint256 amountInPercentage,
                        1, // uint256 minAmountOut)
                        poolsPath,// address[]  calldata encodedCall,
                        tokenAddressPath, // address[] calldata path,
                    ],
                ),
                kyberLiquidityBridge.interface.encodeFunctionData(
                    "addLiquidity",
                    [
                        [buyToken, sellToken], // address[] tokens,
                        poolAddress,
                        [100_000, 100_000], // percentages
                        [1, 1],  // minAmounts,
                        [0, 0], // vReserveRatioBounds
                    ],
                ),
            ];

            // Transfer money to wallet (similar as DeFi Basket contract would have done)
            const transactionHash = await owner.sendTransaction({
                to: wallet.address,
                value: ethers.utils.parseEther("1"), // Sends exactly 1.0 ether
            });
            await transactionHash.wait();

            // Execute bridge calls (buys DAI on Uniswap and deposit on Aave)
            await wallet.useBridges(
                _bridgeAddresses,
                _bridgeEncodedCalls,
            );

            // Wallet token out amount should be 0
            let tokenOut = await ethers.getContractAt("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20", buyToken)
            let tokenOutBalance = await tokenOut.balanceOf(wallet.address);
            expect(tokenOutBalance).to.be.above(0);
        })
    })
});