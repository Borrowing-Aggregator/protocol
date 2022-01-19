function APRtoAPY(depositAPR, variableBorrowAPR, stableBorrowAPR) {
    const SECONDS_PER_YEAR = 31536000;

    // APR to APY
    const depositAPY = ((1 + (depositAPR / SECONDS_PER_YEAR)) ** SECONDS_PER_YEAR) - 1;
    const variableBorrowAPY = ((1 + (variableBorrowAPR / SECONDS_PER_YEAR)) ** SECONDS_PER_YEAR) - 1;
    const stableBorrowAPY = ((1 + (stableBorrowAPR / SECONDS_PER_YEAR)) ** SECONDS_PER_YEAR) - 1;

    return {depositAPY, variableBorrowAPY, stableBorrowAPY};
}

function healthFactor(collateral, borrow) {
    const liquidationThreshold = 0.75;
    const healthfactor = collateral * liquidationThreshold / borrow;

    return healthfactor;
}

function TVL(collateral, borrow) {
    const tvl = borrow / collateral;

    return tvl;
}

function borrowLimitUsed(collateral, borrow) {
    const liquidationThreshold = 0.75;
    const borrowLimitUsed = borrow / (collateral * liquidationThreshold);

    return borrowLimitUsed;
}
