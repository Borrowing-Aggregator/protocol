// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDataprovider {

    function aaveRates() external view returns(uint256, uint256, uint256);
    function aaveIncentives() external view returns(uint256, uint256, uint256, uint256);

}
