// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BAToken.sol";
import "./IStrategy.sol"

import {DataTypes} from './libraries/DataTypes.sol';

contract Vault {


    uint256 public liquidationThreshold = 75;
    address public collateralAsset = "0xd00ae08403B9bbb9124bB305C09058E32C39A48c";
    address public borrowAsset = "0x9668f5f55f2712Dd2dfa316256609b516292D554";

    BAToken baToken;
    IStrategy strategy;

    event Borrow (
        address indexed asset,
        address indexed depositor,
        uint256 indexed amount
    );

    event Repay (
        address indexed asset,
        address indexed depositor,
        uint256 indexed amount
    );

    event Deposit (
        address indexed asset,
        address indexed depositor,
        uint256 indexed amount
    );


    event Withdraw (
        address indexed asset,
        address indexed depositor,
        uint256 indexed amount
    );


    mapping(address => uint) public ids;

    constructor (address _collateralAsset, address _borrowAsset) public {

        // IERC1155 Fuji AVAX
        ids[_collateralAsset] = 0;

        // IERC1155 Fuji WETH
        ids[_borrowAsset] = 1;

    }

    receive() external payable {}

                        ////////////////////////////////
                       //     EXTERNAL FUNCTIONS     //
                      ////////////////////////////////

    function deposit(uint256 amount) external payable {
        require(_amount != 0, "Invalid amount");
        require(msg.value == _amount, "Invalid amount")

        baToken.mint(msg.sender, ids[0], _amount);

        emit Deposit(_collateralAsset, msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external payable {
        uint256 userBalance = baToken.balanceOf(msg.sender, ids[0]);
        require(_amount != 0, "Invalid amount");
        require(msg.value == _amount, "Invalid amount")
        require(_amount <= userBalance, "You dont have enough deposit");

        baToken.burn(msg.sender, ids[0], _amount);
        payable(msg.sender).transfer(_amount);

        emit Withdraw(_collateralAsset, msg.sender, _amount);
    }


    function borrow(uint256 _amount) external payable {
        require(_amount != 0, "Invalid amount");
        require(msg.value == _amount, "Invalid amount")
        uint256 collateralUser = baToken.balanceOf(msg.sender, ids[0]);
        uint256 totalBorrowUser = _amount + baToken.balanceOf(msg.sender, ids[1]);
        uint256 maxBorrowUser = getLimitBorrowAllowed(collateralUser);
        require(totalBorrowUser < maxBorrowUser, "Invalid amount")
        baToken.mint(msg.sender, ids[1], _amount);

        // Active borrow
        uint256 activeStrategy = strategy.getActiveStrategy;
        _borrow(_amount, activeStrategy);

        emit Borrow(_borrowAsset, msg.sender, _amount);
    }

    function repay(uint256 _amount) external payable {
        require(_amount != 0, "Invalid amount");
        require(msg.value == _amount, "Invalid amount")

        uint256 totalBorrowUser = baToken.balanceOf(msg.sender, ids[1]);
        require(totalBorrowUser >= _amount, "Invalid amount")
        baToken.burn(msg.sender, ids[1], _amount);

        emit Repay(_borrowAsset, msg.sender, _amount);
    }

                        ////////////////////////////////
                       //     PRIVATE FUNCTIONS      //
                      ////////////////////////////////

    function _borrow(uint256 _amount, uint256 _strategy) private {
        // INTERFACE WITH AAVE/BENQI
    }

    function _repay(uint256 _amount, uint256 _strategy) private {
        // INTERFACE WITH AAVE/BENQI
    }

                      ////////////////////////////////
                     //     GET FUNCTIONS          //
                    ////////////////////////////////

    function getLimitBorrowAllowed(uint256 _collateralUser) public view returns(uint256){
        return _collateralUser * liquidationThreshold;

    }


}
