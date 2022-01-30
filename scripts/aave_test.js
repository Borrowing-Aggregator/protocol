async function main() {

  // Variables
  const vaultAddr = process.env.VAULT_ADDRESS;
  const aavePoolAddr = process.env.AAVEPOOL_ADDRESS;
  const wEthAddr = process.env.WETH_ADDRESS;
  const wAvaxAddr = process.env.WAVAX_ADDRESS;

  // Contracts
  const vault = await ethers.getContractAt("Vault", vaultAddr);
  const aavePool = await ethers.getContractAt("IAaveLendingPool", aavePoolAddr);
  const wEth = await ethers.getContractAt("IERC20", wEthAddr);
  const wAvax = await ethers.getContractAt("IERC20", wAvaxAddr);

  // Signer
  const [signer] = await ethers.getSigners();

  // Deposit to AAVE
  const amountToDeposit = "1";
  const amount = await ethers.utils.parseEther(amountToDeposit);
  const tx = await vault._withdrawFromProtocol(amount, 0);
  tx.wait();
  console.log("Deposit :", amount.toString());

  const userData = await aavePool.getUserAccountData(vaultAddr);
  console.log("User data :", userData);
  //
  //
  // const {
  //   configuration,
  //   liquidityIndex,
  //   variableBorrowIndex,
  //   currentLiquidityRate,
  //   currentVariableBorrowRate,
  //   currentStableBorrowRate,
  //   lastUpdateTimestamp,
  //   aTokenAddress,
  //   stableDebtTokenAddress,
  //   variableDebtTokenAddress,
  //   interestRateStrategyAddress,
  //   id } = await aavePool.getReserveData(wAvax.address);
  //
  // console.log("Data from user :", aTokenAddress);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
