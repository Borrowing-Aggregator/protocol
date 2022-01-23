// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IOracle.sol";
import "./interfaces/IDataprovider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from './libraries/DataTypes.sol';

contract Strategy is Ownable {

    // Constants
    uint256 RAY = 10 ** 27;
    uint256 WEI_DECIMALS = 10 ** 18; // All emissions are in wei units, 18 decimal places
    uint256 UNDERLYING_TOKEN_DECIMALS = 10 ** 18; // for aUSDC will be 10**6 because USDC has 6 decimals
    uint256 SECONDS_PER_YEAR = 31536000;
    uint256 DECIMALS = 10 ** 6; // to 0.get a 5 digits uint APR like : xxxxx means x,xxxx% APR

    int256 activeStrategy; // 0 : AAVE, 1 : BENQI

    address public collateralAsset;
    address public borrowAsset;

    IDataprovider dataprovider;
    IOracle oracle;

    constructor(address _collateralAsset, address _borrowAsset) public {
        collateralAsset = _collateralAsset;
        borrowAsset = _borrowAsset;
    }

    function initialization(address _dataprovider, address _oracle) external onlyOwner {
      dataprovider = IDataprovider(_dataprovider);
      oracle = IOracle(_oracle);
    }

    function aaveAPR() public view returns(DataTypes.Rates memory) {
        DataTypes.Rates memory rates;

        // Load data from dataprovider and pricefeed
        uint256 priceAVAX = oracle.getUSDPrice(collateralAsset);
        uint256 priceETH =  oracle.getUSDPrice(borrowAsset);
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

        rates.incentiveDepositAPR = DECIMALS*(aEmissionPerYear * priceAVAX * WEI_DECIMALS)/
                              (totalATokenSupply * priceETH * UNDERLYING_TOKEN_DECIMALS);

        rates.incentiveBorrowAPR = DECIMALS*(vEmissionPerYear * priceAVAX * WEI_DECIMALS)/
                              (totalCurrentVariableDebt * priceETH * UNDERLYING_TOKEN_DECIMALS);

        return rates;
    }

    function benqiAPR() public view returns(DataTypes.Rates memory) {
        DataTypes.Rates memory rates;

        return rates;
    }

    // TO DO : ADD CHAINLINK KEEPERSs
    function chooseStrategy() private {
        DataTypes.Rates memory aaveRates = aaveAPR();
        DataTypes.Rates memory benqiRates = benqiAPR();

        int256 aaveBorrowAPR = int256(aaveRates.variableBorrowAPR) - int256(aaveRates.incentiveBorrowAPR);
        int256 benqiBorrowAPR = int256(benqiRates.variableBorrowAPR) - int256(benqiRates.incentiveBorrowAPR);

        // TO DO : WRITE BETTER STRATEGY
        if (aaveBorrowAPR > benqiBorrowAPR) {
            activeStrategy = 0;
        } else {
            activeStrategy = 1;
        }
    }

    function getActiveStrategy() public view returns(int256) {
        return activeStrategy;
    }

}
