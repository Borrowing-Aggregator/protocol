// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {

    function getUSDPrice(address _asset) external view  returns (uint256);
    function getPairPrice(address _collateral, address _borrow) external view returns (uint256);

}
