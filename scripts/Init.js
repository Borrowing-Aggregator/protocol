async function main() {
  const addrPool = process.env.POOL_ADDRESS;
  const addrController = process.env.CONTROLLER_ADDRESS;
  const addrUSDT = process.env.USDT_ADDRESS;
  const pool = await hre.ethers.getContractAt("ILendingPool", addrPool);

  await pool.getReserveData(addrUSDT);
  console.log(await pool.getReserveData(addrUSDT));

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
