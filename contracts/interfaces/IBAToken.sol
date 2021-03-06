// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBAToken is IERC1155 {
    function mint(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;

    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external;

    function getTotalSupply(uint256 id) external view returns (uint256);
}
