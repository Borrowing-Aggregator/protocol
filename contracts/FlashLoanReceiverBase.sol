pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IFlashLoanReceiver.sol";
import "./interfaces/IAaveLendingPoolAddressesProvider.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {

    using SafeERC20 for IERC20;

    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IAaveLendingPoolAddressesProvider public addressesProvider;

    constructor(address _addressProvider) {
        addressesProvider = IAaveLendingPoolAddressesProvider(_addressProvider);
    }

    receive() payable external {}

    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {
        address payable core = addressesProvider.getLendingPoolCore();
        transferInternal(core, _reserve, _amount);
    }

    function transferInternal(address payable _destination, address _reserve, uint256 _amount) internal {
        if(_reserve == ethAddress) {
            (bool success, ) = _destination.call{value: _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_reserve).safeTransfer(_destination, _amount);
    }

    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == ethAddress) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }
}
