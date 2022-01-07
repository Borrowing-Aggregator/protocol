// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IOracle.sol";

contract Oracle is IOracle {

    AggregatorV3Interface internal priceAVAX;
    AggregatorV3Interface internal priceETH;

    /**
     * Network: Fuji
     *
     * Aggregator: AVAX/USD
     * Address: 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD
     *
     * Aggregator: ETH/USD
     * Address: 0x86d67c3D38D2bCeE722E601025C25a575021c6EA
     */
    constructor() {
        priceAVAX = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
        priceETH = AggregatorV3Interface(0x86d67c3D38D2bCeE722E601025C25a575021c6EA);
    }

    /**
     * Returns the latest price
     */
    function getAVAXPrice() public view override returns (int) {
        (,int price,,,) = priceAVAX.latestRoundData();
        return price;
    }

    function getETHPrice() public view override returns (int) {
        (,int price,,,) = priceETH.latestRoundData();
        return price;
    }
}
