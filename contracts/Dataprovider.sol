//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IAaveIncentivesController.sol";
import "./dependencies/openzeppelin/contracts/IERC20.sol";
import "./interfaces/IDataprovider.sol";
import "./interfaces/QiTokenInterfaces.sol";

import {DataTypes} from './libraries/DataTypes.sol';

contract Dataprovider is IDataprovider {

    ILendingPool pool;
    IAaveIncentivesController incentives;
    QiTokenInterface qiToken;

    address public asset;

    // Fuji AAVE lending pool : 0x76cc67FF2CC77821A70ED14321111Ce381C2594D
    // Fuji AAVE incentives controller : 0xa1EF206fb9a8D8186157FC817fCddcC47727ED55
    // Fuji AAVE WETH : 0x9668f5f55f2712Dd2dfa316256609b516292D554
    // Fuji AAVE WAVAX : 0xd00ae08403B9bbb9124bB305C09058E32C39A48c

    // Fuji BENQI QIToken : 0xe401e9ce0e354ad9092a63ee1dfa3168bb83f3da

    constructor (address _pool, address _incentives, address _qiToken, address _asset) public {
        pool = ILendingPool(_pool);
        incentives = IAaveIncentivesController(_incentives);
        qiToken = QiTokenInterface(_qiToken);
        asset = _asset;
    }

    function aaveRates() public view override returns(uint256, uint256, uint256) {
        DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);

        uint256 liquidityRate = reserveData.currentLiquidityRate;
        uint256 variableBorrowRate = reserveData.currentVariableBorrowRate;
        uint256 stableBorrowRate = reserveData.currentStableBorrowRate;

        return (liquidityRate, variableBorrowRate, stableBorrowRate);
    }

    function aaveIncentives() public view override returns(uint256, uint256, uint256, uint256) {
        DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);

        address aTokenAddress = reserveData.aTokenAddress;
        address variableDebtTokenAddress = reserveData.variableDebtTokenAddress;

        (,uint256 aEmissionPerSecond,) = incentives.getAssetData(aTokenAddress);
        (,uint256 vEmissionPerSecond,) = incentives.getAssetData(variableDebtTokenAddress);

        uint256 totalATokenSupply = IERC20(aTokenAddress).totalSupply();
        uint256 totalCurrentVariableDebt = IERC20(variableDebtTokenAddress).totalSupply();

        return (aEmissionPerSecond, vEmissionPerSecond, totalATokenSupply, totalCurrentVariableDebt);
    }

    function benqirates() public view returns(uint256) {
        uint256 borrowRatePerTimestamp = qiToken.borrowRatePerTimestamp();
        return borrowRatePerTimestamp;
    }


}
