async function main() {

  // Variables
  const vaultAddr = '0x7b7ab386AEAc8679c992cE22b4E251787913abF4';
  // const baTokenAddr = process.env.BATOKEN_ADDRESS;
  const wavaxAddress = '0xd00ae08403B9bbb9124bB305C09058E32C39A48c';

  // Signer
  const [signer] = await ethers.getSigners();
  console.log("Hardhat connected to: ", signer.address);

  // Init contracts
  const vault = await ethers.getContractAt("Vault", vaultAddr);
  // const baToken = await ethers.getContractAt("IBAToken", baTokenAddr);
  const wavax = await ethers.getContractAt("IERC20", wavaxAddress);

  // Deposit
  const deposit = "0.0001";
  const amountToDeposit = await ethers.utils.parseEther(deposit);
  await wavax.approve('0x7b7ab386AEAc8679c992cE22b4E251787913abF4', amountToDeposit);
  await vault.deposit(amountToDeposit)

  // Metrics
  const balanceVault = await wavax.balanceOf(vault.address);
  console.log("Balance contract :", balanceVault.toString());

  const balanceBAToken = await vault.getDebtCollateralToken();
  console.log("Balance BAToken :", balanceBAToken.toString());

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
