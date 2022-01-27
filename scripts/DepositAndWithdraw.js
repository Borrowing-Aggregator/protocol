async function main() {

  // Variables
  const vaultAddr = process.env.VAULT_ADDRESS;
  const baTokenAddr = process.env.BATOKEN_ADDRESS;
  const wEthAddr = process.env.WETH_ADDRESS;

  // Signer
  const [signer] = await ethers.getSigners();
  console.log("Hardhat connected to: ", signer.address);

  // Init contracts
  const vault = await ethers.getContractAt("Vault", vaultAddr);
  const baToken = await ethers.getContractAt("IBAToken", baTokenAddr);
  const wEth = await ethers.getContractAt("IERC20", wEthAddr);

  // Deposit
  const deposit = "1";
  const amountToDeposit = await ethers.utils.parseEther(deposit);
  await vault.deposit(amountToDeposit, { value: amountToDeposit })

  // Metrics
  const balanceVault = await ethers.provider.getBalance(vault.address);
  console.log("Balance contract :", balanceVault.toString());

  const balanceBAToken = await vault.getDebtCollateralToken();
  console.log("Balance BAToken :", balanceCollateralBAToken.toString());

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
