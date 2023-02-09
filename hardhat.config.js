require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: ".env" });
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.15",
        settings: {
            optimizer: {
                enabled: true,
                runs: 2000,
            }
        }
    },
    networks: {
        alfajores: {
            url: process.env.RPC_URL,
            chainId: 44787,
            accounts: {
                mnemonic: process.env.MNEMONIC,
                path: "m/44'/60'/0'/0",
            }
        },
    },
    gasReporter: {
        token: "CELO",
        currency: "USD",
        gasPrice: 21,
        enabled: true,
    },
};
