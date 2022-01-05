//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IAaveIncentivesController.sol";
import "./interfaces/IERC20.sol";
import {DataTypes} from './libraries/DataTypes.sol';

contract Dataprovider {

    address public owner;
    ILendingPool pool;
    IAaveIncentivesController incentives;
    address public coin;

    // AAVE lending pool : 0x76cc67FF2CC77821A70ED14321111Ce381C2594D
    // AAVE incentives controller : 0xa1EF206fb9a8D8186157FC817fCddcC47727ED55
    // WETH : 0x9668f5f55f2712Dd2dfa316256609b516292D554
    // WAVAX : 0xd00ae08403B9bbb9124bB305C09058E32C39A48c

    constructor(ILendingPool _pool, IAaveIncentivesController _incentives, address _coin) public {
        owner = msg.sender;
        pool = _pool;
        coin = _coin;
        incentives = _incentives;
    }

    function aaveRates() public view returns(uint, uint, uint) {
        DataTypes.ReserveData memory reserveData = pool.getReserveData(coin);

        uint256 liquidityRate = reserveData.currentLiquidityRate;
        uint256 variableBorrowRate = reserveData.currentVariableBorrowRate;
        uint256 stableBorrowRate = reserveData.currentStableBorrowRate;

        return (liquidityRate, variableBorrowRate, stableBorrowRate);
    }

    function aaveIncentives() public view returns(uint, uint, uint) {
        DataTypes.ReserveData memory reserveData = pool.getReserveData(coin);

        address aTokenAddress = reserveData.aTokenAddress;
        address variableDebtTokenAddress = reserveData.variableDebtTokenAddress;
        address stableDebtTokenAddress = reserveData.stableDebtTokenAddress;

        (,uint256 aEmissionPerSecond,) = incentives.getAssetData(aTokenAddress);
        (,uint256 vEmissionPerSecond,) = incentives.getAssetData(variableDebtTokenAddress);

        return (aEmissionPerSecond, vEmissionPerSecond);
    }

}
