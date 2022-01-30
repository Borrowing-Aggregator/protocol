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
  const wEth = await ethers.getContractAt("IERC20", wEthAddr);
  const wAvax = await ethers.getContractAt("IERC20", wAvaxAddr);

  // Deposit
  const withdraw = "1";
  const amountToWithdraw = await ethers.utils.parseEther(withdraw);
  await wAvax.approve(vault.address, amountToWithdraw);
  const tx = await vault.withdraw(amountToWithdraw);
  tx.wait();

  // Metrics after withdraw
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
