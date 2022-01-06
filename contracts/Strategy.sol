// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IOracle.sol";
import "./interfaces/IDataprovider.sol";

import {DataTypes} from './libraries/DataTypes.sol';

contract Strategy {

    IDataprovider dataprovider;
    IOracle pricefeed;

    uint256 RAY = 10 ** 27;
    uint256 WEI_DECIMALS = 10 ** 18; // All emissions are in wei units, 18 decimal places
    uint256 UNDERLYING_TOKEN_DECIMALS = 10 ** 18; // for aUSDC will be 10**6 because USDC has 6 decimals
    uint256 SECONDS_PER_YEAR = 31536000;
    uint256 DECIMALS = 10 ** 6; // to get a 5 digits uint APR like : xxxxx means x,xxxx% APR

    constructor (IDataprovider _dataprovider, IOracle _pricefeed) public {
        dataprovider = _dataprovider;
        pricefeed = _pricefeed;
    }

    function aaveAPR() public view returns(DataTypes.Rates memory) {
        DataTypes.Rates memory rates;

        // Load data from dataprovider and pricefeed
        uint256 priceAVAX = uint256(pricefeed.getAVAXPrice());
        uint256 priceETH =  uint256(pricefeed.getETHPrice());
        (
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate
        ) = dataprovider.aaveRates();
        (
            uint256 aEmissionPerSecond,
            uint256 vEmissionPerSecond,
            uint256 totalATokenSupply,
            uint256 totalCurrentVariableDebt
        ) = dataprovider.aaveIncentives();

        // Deposit and Borrow calculations
        // APY and APR are returned here as decimals, multiply by 100 to get the percents
        rates.depositAPR = liquidityRate * DECIMALS/RAY;
        rates.variableBorrowAPR = variableBorrowRate * DECIMALS/RAY;
        rates.stableBorrowAPR = stableBorrowRate * DECIMALS/RAY;

        // Incentives calculation
        uint256 aEmissionPerYear = aEmissionPerSecond * SECONDS_PER_YEAR;
        uint256 vEmissionPerYear = vEmissionPerSecond * SECONDS_PER_YEAR;

        rates.incentiveDepositAPRPercent = DECIMALS*(aEmissionPerYear * priceAVAX * WEI_DECIMALS)/
                              (totalATokenSupply * priceETH * UNDERLYING_TOKEN_DECIMALS);

        rates.incentiveBorrowAPRPercent = DECIMALS*(vEmissionPerYear * priceAVAX * WEI_DECIMALS)/
                              (totalCurrentVariableDebt * priceETH * UNDERLYING_TOKEN_DECIMALS);

        return rates;
    }

}
