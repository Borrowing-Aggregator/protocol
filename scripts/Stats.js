async function main() {

  // Variables
  const vaultAddr = process.env.VAULT_ADDRESS;
  const aavePoolAddr = process.env.AAVEPOOL_ADDRESS;
  const baTokenAddr = process.env.BATOKEN_ADDRESS;
  const wEthAddr = process.env.WETH_ADDRESS;
  const wAvaxAddr = process.env.WAVAX_ADDRESS;
  const oracleAddr = process.env.ORACLE_ADDRESS;

  // Signer
  const [signer] = await ethers.getSigners();
  console.log("Hardhat connected to: ", signer.address);

  // Init contracts
  const vault = await ethers.getContractAt("Vault", vaultAddr);
  const aavePool = await ethers.getContractAt("IAaveLendingPool", aavePoolAddr);
  const baToken = await ethers.getContractAt("IBAToken", baTokenAddr);
  const wAvax = await ethers.getContractAt("IERC20", wAvaxAddr);
  const oracle = await ethers.getContractAt("IOracle", oracleAddr);

  // Metrics
  const balanceVault = await wAvax.balanceOf(vault.address);
  console.log("Balance contract :", balanceVault.toString());

  const userData = await aavePool.getUserAccountData(vaultAddr);
  console.log("Balance AAVE (ETH) :", userData.totalCollateralETH.toString());

  const pairPrice = await oracle.getPairPrice(wAvaxAddr, wEthAddr);
  console.log("pair price :", pairPrice.toString());


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
