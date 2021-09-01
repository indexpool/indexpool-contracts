import {ethers} from "hardhat";
import constants from "../constants";
import {BigNumber} from "ethers";
import {MongoClient} from "mongodb";

const weiToString = (wei) => {
    return wei
        .div(
            BigNumber.from(10).pow(14)
        )
        .toNumber() / Math.pow(10, 4);
}

const getDeployedAddress = async (contractName, client) => {
    return (await client
        .db('indexpool')
        .collection('contracts')
        .findOne(
            {
                'name': contractName
            }
        ))['address'];
}

async function main() {
    const ADDRESSES = constants['POLYGON'];
    const TOKENS = constants['POLYGON']['TOKENS'];

    const client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();

    let indexPool = await ethers.getContractAt("IndexPool",
        await getDeployedAddress("IndexPool", client));

    let uniswapV2SwapBridge = await ethers.getContractAt("QuickswapSwapBridge",
        await getDeployedAddress("QuickswapSwapBridge", client));

    let aaveV2DepositBridge = await ethers.getContractAt("AaveV2DepositBridge",
        await getDeployedAddress("AaveV2DepositBridge", client));

    const [deployer] = await ethers.getSigners();
    const balanceBegin = await deployer.getBalance();
    console.log("Deploying from:", deployer.address);
    console.log("Account balance:", weiToString(balanceBegin));

    var _bridgeAddresses = [
        uniswapV2SwapBridge.address,
        aaveV2DepositBridge.address,
    ];
    var _bridgeEncodedCalls = [
        uniswapV2SwapBridge.interface.encodeFunctionData(
            "tradeFromETHToToken",
            [
                ADDRESSES['UNISWAP_V2_ROUTER'],
                100000,
                1,
                [
                    TOKENS['WMAIN'],
                    TOKENS['DAI'],
                ]
            ],
        ),
        aaveV2DepositBridge.interface.encodeFunctionData(
            "deposit",
            [
                TOKENS['DAI'],
                100000
            ]
        )
    ];

    let overrides = {value: ethers.utils.parseEther("0.000001"), gasLimit:2000000};
    await indexPool.createPortfolio(
        {'tokens': [], 'amounts': []},
        _bridgeAddresses,
        _bridgeEncodedCalls,
        overrides
    );
    console.log("Mint succeeded:", weiToString(balanceBegin));
    console.log("Account balance:", weiToString(balanceBegin));

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
