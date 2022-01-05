function aaveDatas(liquidityRate, variableBorrowRate, stableBorrowRate, aEmissionPerSecond, vEmissionPerSecond) {
    const RAY = 10 ** 27; // 10 to the power 27
    const SECONDS_PER_YEAR = 31536000;
    const WEI_DECIMALS = 10**18 // All emissions are in wei units, 18 decimal places
    const UNDERLYING_TOKEN_DECIMALS = 10**6 // for aUSDC will be 10**6 because USDC has 6 decimals

    // Deposit and Borrow calculations
    // APY and APR are returned here as decimals, multiply by 100 to get the percents
    const depositAPR = liquidityRate/RAY;
    const variableBorrowAPR = variableBorrowRate/RAY;
    const stableBorrowAPR = stableBorrowRate/RAY;

    // APR to APY
    const depositAPY = ((1 + (depositAPR / SECONDS_PER_YEAR)) ** SECONDS_PER_YEAR) - 1;
    const variableBorrowAPY = ((1 + (variableBorrowAPR / SECONDS_PER_YEAR)) ** SECONDS_PER_YEAR) - 1;
    const stableBorrowAPY = ((1 + (stableBorrowAPR / SECONDS_PER_YEAR)) ** SECONDS_PER_YEAR) - 1;

    // Incentives calculation

    aEmissionPerYear = aEmissionPerSecond * SECONDS_PER_YEAR
    vEmissionPerYear = vEmissionPerSecond * SECONDS_PER_YEAR

    //
    // TO DO : totalATokenSupply, REWARD_PRICE_ETH, TOKEN_PRICE_ETH, totalCurrentVariableDebt, UNDERLYING_TOKEN_DECIMALS
    //

    const incentiveDepositAPRPercent = 100 * (aEmissionPerYear * REWARD_PRICE_ETH * WEI_DECIMALS)/
                              (totalATokenSupply * TOKEN_PRICE_ETH * UNDERLYING_TOKEN_DECIMALS)

    const incentiveBorrowAPRPercent = 100 * (vEmissionPerYear * REWARD_PRICE_ETH * WEI_DECIMALS)/
                              (totalCurrentVariableDebt * TOKEN_PRICE_ETH * UNDERLYING_TOKEN_DECIMALS)

    return {depositAPY, variableBorrowAPY, stableBorrowAPY, incentiveDepositAPRPercent, incentiveBorrowAPRPercent};
}
