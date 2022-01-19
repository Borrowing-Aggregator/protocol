// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IOracle.sol";

contract Oracle is IOracle {

    address collateralAsset;
    address collateralAggregator;
    address borrowAsset;
    address borrowAggregator;

    mapping(address => address) usdPriceFeed;

    /**
     * Network: Fuji
     * Pair : AVAX/USD
     * Address : 0xd00ae08403B9bbb9124bB305C09058E32C39A48c
     * Aggregator: 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD
     *
     * Pair: ETH/USD
     * Address : 0x9668f5f55f2712Dd2dfa316256609b516292D554
     * Aggregator: 0x86d67c3D38D2bCeE722E601025C25a575021c6EA
     */

    constructor(address _collateralAsset, address _borrowAsset, address _collateralAggregator, address _borrowAggregator) public {
        // IERC1155 Fuji AVAX
        collateralAsset = _collateralAsset;
        collateralAggregator = _collateralAggregator;
        usdPriceFeed[collateralAsset] = collateralAggregator;
        // IERC1155 Fuji WETH
        borrowAsset = _borrowAsset;
        borrowAggregator = _borrowAggregator;
        usdPriceFeed[borrowAsset] = borrowAggregator;
    }

    function getUSDPrice(address _asset) public view override returns (uint256) {
        (,int256 latestprice,,,) = AggregatorV3Interface(usdPriceFeed[_asset]).latestRoundData();
        uint256 price = uint256(latestprice);

        return price;
    }

    // both have 18 decimals !
    function getPairPrice(address _collateral, address _borrow) external view override returns (uint256) {
      uint256 price = getUSDPrice(_collateral) / getUSDPrice(_borrow);

      return price;
    }

}
