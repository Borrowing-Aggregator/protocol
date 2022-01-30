async function main() {

  // Variables
  const vaultAddr = process.env.VAULT_ADDRESS;
  const baTokenAddr = process.env.BATOKEN_ADDRESS;
  const wEthAddr = process.env.WETH_ADDRESS;
  const wAvaxAddr = process.env.WAVAX_ADDRESS;

  // Signer
  const [signer] = await ethers.getSigners();
  console.log("Hardhat connected to: ", signer.address);

  // Init contracts
  const vault = await ethers.getContractAt("Vault", vaultAddr);
  const baToken = await ethers.getContractAt("IBAToken", baTokenAddr);
  const wAvax = await ethers.getContractAt("IERC20", wAvaxAddr);

  // Deposit
  const deposit = "1";
  const amountToDeposit = await ethers.utils.parseEther(deposit);
  await wAvax.approve(vault.address, amountToDeposit);
  const tx = await vault.deposit(amountToDeposit);
  tx.wait();

  // Metrics after deposit
  balanceVault = await wAvax.balanceOf(vault.address);
  console.log("Balance contract :", balanceVault.toString());

  balanceBAcollateral = await vault.getDebtCollateralToken();
  console.log("Balance BA collateral :", balanceBAcollateral.toString());

  balanceBAborrow = await vault.getDebtBorrowToken();
  console.log("Balance BA borrow :", balanceBAborrow.toString());

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
