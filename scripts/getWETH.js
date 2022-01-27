async function main() {

  const wAvaxAddr = process.env.WAVAX_ADDRESS;

  // Signer
  const [signer] = await ethers.getSigners();
  console.log("Signing contracts with the account: " + signer.address);

  // wAvax
  const wAvax = await ethers.getContractAt("IWAvax", wAvaxAddr);

  // Get an amount of WETH
  const amount = "1";
  const amountAvax = ethers.utils.parseEther(amount);
  await wAvax.approve(signer.address, amountAvax);
  await wAvax.deposit({ value: amountAvax});
  console.log("Sending", amount.toString(), "Avax for", amount.toString(), "WAvax");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
