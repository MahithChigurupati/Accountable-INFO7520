import { ethers } from "hardhat"
export interface networkConfigItem {
    name?: string
    ethUsdPriceFeed?: string
    blockConfirmations?: number
}

export interface networkConfigInfo {
    [key: number]: networkConfigItem
}

export const networkConfig: networkConfigInfo = {
    1337: {
        name: "hardhat",
        blockConfirmations: 0,
    },
    31337: {
        name: "localhost",
        blockConfirmations: 0,
    },
    42161: {
        name: "arbitrum one",

        // price feed from https://docs.chain.link/data-feeds/price-feeds/addresses
        ethUsdPriceFeed: "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612",
        blockConfirmations: 6,
    },
    421613: {
        name: "arbitrum goerli",

        // price feed from https://docs.chain.link/data-feeds/price-feeds/addresses
        ethUsdPriceFeed: "0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08",
        blockConfirmations: 6,
    },
}

export const developmentChains = ["hardhat", "localhost"]
export const testnetChains = ["goerli"]

export const frontEndContractsFile = "../Accountable-INFO7520-UI/constants/contractAddresses.json"
export const frontEndAbiFile = "../Accountable-INFO7520-UI/constants/abi.json"

export const DECIMALS = "18"
export const AGGREGATOR_INITIAL_PRICE = ethers.parseEther("2000")
