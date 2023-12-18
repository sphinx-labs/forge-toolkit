// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseChainSetup} from "./BaseChainSetup.sol";
import {IQuoter} from "@uniswap/v3-periphery/interfaces/IQuoter.sol";
import {ChainAliases} from "./ChainAliases.sol";

contract UniswapRouterHelpers is BaseChainSetup, ChainAliases {
    mapping(string => IQuoter) quoterLookup;
    mapping(string => address) public uniswapperLookup;

    uint24 constant DEFAULT_TICK_SIZE = 100;
    address constant COMMON_SWAPROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant COMMON_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    function getUniRouter(string memory chain) public view returns (address) {
        return uniswapperLookup[chain];
    }

    function _switchAndGetQuoter(
        string memory chain
    ) private returns (IQuoter quoter) {
        switchTo(chain);
        quoter = quoterLookup[chain];
    }

    function quoteIn(
        string memory chain,
        bytes memory path,
        uint256 amountIn
    ) public returns (uint256) {
        if (path.length == 0) {
            return amountIn;
        }
        return _switchAndGetQuoter(chain).quoteExactInput(path, amountIn);
    }

    function quoteOut(
        string memory chain,
        bytes memory path,
        uint256 amountOut
    ) public returns (uint256) {
        if (path.length == 0) {
            return amountOut;
        }
        return _switchAndGetQuoter(chain).quoteExactOutput(path, amountOut);
    }

    function _onePathOut(
        string memory chain,
        address srcToken,
        address dstToken,
        uint24 tickSize
    ) private view returns (bytes memory path) {
        srcToken = srcToken == address(0) ? wethLookup[chain] : srcToken;
        dstToken = dstToken == address(0) ? wethLookup[chain] : dstToken;
        if (srcToken == dstToken) {
            return "";
        }
        return abi.encodePacked(dstToken, tickSize, srcToken);
    }

    function pathIn(
        string memory chain,
        address srcToken,
        address dstToken
    ) public view returns (bytes memory path) {
        return _onePathIn(chain, srcToken, dstToken, DEFAULT_TICK_SIZE);
    }

    function pathOut(
        string memory chain,
        address srcToken,
        address dstToken
    ) public view returns (bytes memory path) {
        return _onePathOut(chain, srcToken, dstToken, DEFAULT_TICK_SIZE);
    }

    function _onePathIn(
        string memory chain,
        address srcToken,
        address dstToken,
        uint24 tickSize
    ) private view returns (bytes memory path) {
        srcToken = srcToken == address(0) ? wethLookup[chain] : srcToken;
        dstToken = dstToken == address(0) ? wethLookup[chain] : dstToken;
        if (srcToken == dstToken) {
            return bytes("");
        }
        return abi.encodePacked(srcToken, tickSize, dstToken);
    }

    // from here: https://docs.uniswap.org/contracts/v3/reference/deployments
    function loadAllUniRouterInfo() public {
        uniswapperLookup[ethereum] = COMMON_SWAPROUTER;
        uniswapperLookup[arbitrum] = COMMON_SWAPROUTER;
        uniswapperLookup[optimism] = COMMON_SWAPROUTER;
        uniswapperLookup[polygon] = COMMON_SWAPROUTER;
        vm.label(COMMON_SWAPROUTER, "Uniswap Swapper");
        quoterLookup[ethereum] = IQuoter(COMMON_QUOTER);
        quoterLookup[arbitrum] = IQuoter(COMMON_QUOTER);
        quoterLookup[optimism] = IQuoter(COMMON_QUOTER);
        quoterLookup[polygon] = IQuoter(COMMON_QUOTER);
        vm.label(COMMON_QUOTER, "Uniswap Quoter");
    }
}
