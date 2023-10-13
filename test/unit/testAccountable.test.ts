import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { assert, expect } from "chai"
import { network, deployments, ethers } from "hardhat"
import {
    developmentChains,
    AGGREGATOR_INITIAL_PRICE,
    INITIAL_MINT_FEE,
    INCREMENT_THRESHOLD,
    ONE,
    LOW_MINT_FEE,
    SEND_MINT_FEE,
} from "../../helper-hardhat-config"
import {
    Accountable,
    MockV3Aggregator,
    MockWethToken,
    MockWbtcToken,
    MockUsdcToken,
} from "../../typechain-types"

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("AvatarNFTMe", function () {
          let accountable: Accountable
          let mockV3Aggregator: MockV3Aggregator
          let wethTokenAddress: MockWethToken
          let wbtcTokenAddress: MockWbtcToken
          let usdcTokenAddress: MockUsdcToken
          let deployer: SignerWithAddress
          let user: SignerWithAddress

          const UNSUPPORTED_TOKEN_ADDRESS = "0xdD2FD4581271e230360230F9337D5c0430Bf44C0"
          const dummyToken = "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E"
          const dummyTokenPriceFeed = "0xdD2FD4581271e230360230F9337D5c0430Bf44C0"

          beforeEach(async () => {
              const accounts = await ethers.getSigners()
              deployer = accounts[0]
              user = accounts[1]

              await deployments.fixture(["all"])
              accountable = await ethers.getContract("accountable", deployer)

              mockV3Aggregator = await ethers.getContract("MockV3Aggregator", deployer)

              wethTokenAddress = await ethers.getContract("MockWethToken", deployer)

              wbtcTokenAddress = await ethers.getContract("MockWbtcToken", deployer)
              usdcTokenAddress = await ethers.getContract("MockUsdcToken", deployer)
          })

          describe("constructor", function () {
              it("sets the owner addresses correctly", async () => {
                  const response = await accountable.owner()
                  assert.equal(response, deployer.address)
              })
              it("sets the NFT Name correctly", async () => {
                  const response = await avatarNftMe.name()
                  assert.equal(response, NAME)
              })

              it("sets the NFT Symbol correctly", async () => {
                  const response = await avatarNftMe.symbol()
                  assert.equal(response, SYMBOL)
              })

              it("sets the ETH / USD address correctly", async () => {
                  const response = await avatarNftMe.getTokenPriceFeed(wethTokenAddress)
                  assert.equal(response, mockV3Aggregator.target)
              })

              it("sets the BTC / USD price feed address correctly", async () => {
                  const response = await avatarNftMe.getTokenPriceFeed(wbtcTokenAddress)
                  assert.equal(response, mockV3Aggregator.target)
              })

              it("sets the USDC / USD price feed address correctly", async () => {
                  const response = await avatarNftMe.getTokenPriceFeed(usdcTokenAddress)
                  assert.equal(response, mockV3Aggregator.target)
              })

              it("sets the native chain aggregator address correctly", async () => {
                  const response = await avatarNftMe.getNativeChainPriceFeed()
                  assert.equal(response, mockV3Aggregator.target)
              })
          })

          describe("Contract Level Metdata", function () {
              it("sets the webpage correctly", async () => {
                  const tx = avatarNftMe.setCurrentWebPageUri(WEBPAGE_URI)
                  await expect(tx)
                      .to.emit(avatarNftMe, "officialWebpageUriUpdated")
                      .withArgs(WEBPAGE_URI)

                  const response = await avatarNftMe.getCurrentWebPageUri()
                  assert.equal(response, WEBPAGE_URI)
              })
          })

          describe("Mint NFT", function () {
              it("Revert due to no balance & no allowance of tokens", async () => {
                  const response = avatarNftMe.formTokenUriAndMintWithToken(
                      wethTokenAddress,
                      SEND_MINT_FEE,
                      FIRST_NAME,
                      LAST_NAME,
                      WEBSITE,
                      BODY_TYPE,
                      OUTFIT_GENDER,
                      SKIN_TONE,
                      CREATED_AT,
                      IMAGE_URI,
                  )
                  await expect(response).to.be.revertedWith("ERC20: insufficient allowance")
              })
          })

          describe("Miscellaneous ", function () {
              it("add support for a new token", async () => {
                  const response = await avatarNftMe.addTokenSupport(
                      dummyToken,
                      dummyTokenPriceFeed,
                  )

                  const addedTokenPriceFeed = await avatarNftMe.getTokenPriceFeed(dummyToken)
                  assert.equal(addedTokenPriceFeed, dummyTokenPriceFeed)
              })
          })

          describe("view", function () {
              it("get initial price", async () => {
                  const response = await avatarNftMe.getInitialPrice()
                  assert.equal(response, INITIAL_MINT_FEE)
              })
          })
      })

// also check balances of buyer and seller
