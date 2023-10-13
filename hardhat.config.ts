import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "@nomicfoundation/hardhat-ethers"
import "hardhat-deploy"

import dotenv from "dotenv"

dotenv.config()

// RPC URLS
const ARBITRIUM_GOERLI_RPC_URL = process.env.ARBITRIUM_GOERLI_RPC_URL || ""
const ARBITRIUM_MAINNET_RPC_URL = process.env.ARBITRIUM_MAINNET_RPC_URL || ""

// PRIVATE KEYS
const LOCALHOST_PRIVATE_KEY = process.env.LOCALHOST_PRIVATE_KEY || ""
const PRIVATE_KEY = process.env.PRIVATE_KEY || ""
//////// MAINNETS /////////
// const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY || ""

// API KEYS
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || ""

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.8.20",
            },
            {
                version: "0.6.6",
            },
        ],
    },

    networks: {
        hardhat: {
            chainId: 1337,
        },
        localhost: {
            url: "http://localhost:8545",
            chainId: 31337,
            accounts: [LOCALHOST_PRIVATE_KEY],
        },

        arbitrumGoerli: {
            url: ARBITRIUM_GOERLI_RPC_URL,
            chainId: 421613,
            accounts: [PRIVATE_KEY],
        },
        arbitrum: {
            url: ARBITRIUM_MAINNET_RPC_URL,
            chainId: 42161,
            accounts: [PRIVATE_KEY],
        },
    },

    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },

    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        coinmarketcap: COINMARKETCAP_API_KEY,
    },

    namedAccounts: {
        deployer: {
            default: 0,
        },
        user: {
            default: 1,
        },
    },
}

export default config
