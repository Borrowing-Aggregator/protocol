// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface WAVAX {

    function deposit() external payable;
    function withdraw() external payable;
    function approve(address addr, uint256 amount) external;

}
