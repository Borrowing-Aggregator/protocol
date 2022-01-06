// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {

    function getAVAXPrice() external view returns (int);
    function getETHPrice() external view returns (int);

}
