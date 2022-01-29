// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQiComptroller {

    function enterMarkets(address[] calldata qiTokens) external returns (uint[] memory);
    function exitMarket(address qiToken) external returns (uint);

  }
