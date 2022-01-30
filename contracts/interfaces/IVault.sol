// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function initialization(
        address _oracle,
        address _strategy,
        address _baToken,
        address _aavePool,
        address _qiAvax,
        address _qiComptroller
    ) external;

    function deposit(uint256 _amountToDeposit) external payable;

    function withdraw(uint256 _amountToWithdraw) external payable;

    function borrow(uint256 _amountToBorrow) external payable;

    function repay(uint256 _amountToRepay) external payable;

    function getHealthFactor() external view returns (uint256);

    function getTVL() external view returns (uint256);

    function getBorrowLimitUsed() external view returns (uint256);

    function changeProtocol() external payable;
}
