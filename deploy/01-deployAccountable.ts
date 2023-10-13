import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import verify from "../utils/verify"
import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployAccountable: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    // @ts-ignore
    const { getNamedAccounts, deployments, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId: number = network.config.chainId!

    let ethUsdPriceFeedAddress: string
    let args: any[] = []

    if (chainId == 31337 || chainId == 1337) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId].ethUsdPriceFeed!
    }

    log("----------------------------------------------------")
    log("Deploying Avatar NFT Me and waiting for confirmations...")

    const priceFeeds = [ethUsdPriceFeedAddress]

    args = []

    const accountable = await deploy("Accountable", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: networkConfig[chainId].blockConfirmations || 0,
    })

    log(`accountable deployed at ${accountable.address}`)

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(accountable.address, args)
    }
}
export default deployAccountable
deployAccountable.tags = ["all", "avatarNftMe"]
