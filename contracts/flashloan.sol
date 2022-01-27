//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./FlashLoanReceiverBase.sol";
import "./interfaces/IAaveLendingPoolAddressesProvider.sol";
import "./interfaces/IAaveLendingPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Flashloan is FlashLoanReceiverBase, Ownable {
    constructor(address _addressProvider)
        public
        FlashLoanReceiverBase(_addressProvider)
    {}

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        require(
            _amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance, was the flashLoan successful?"
        );

        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //

        uint256 totalDebt = _amount + _fee;
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(address _asset, uint256 amount) public onlyOwner {
        address[] memory assets = new address[](1);
        assets[0] = _asset;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        IAaveLendingPool lendingPool = IAaveLendingPool(
            addressesProvider.getLendingPool()
        );
        lendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
}
