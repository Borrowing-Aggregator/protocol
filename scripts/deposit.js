async function main() {

  const aavePoolAddr = process.env.AAVEPOOL_ADDRESS;
  const aaveIncentivesAddr = process.env.AAVEICENTIVES_ADDRESS;
  const qiToken = process.env.QITOKEN_ADDRESS;
  const wEthAddr = process.env.WETH_ADDRESS;
  const wAvaxAddr = process.env.WAVAX_ADDRESS;
  const wethAggregatorAddr = process.env.ETH_AGG_ADDRESS;
  const avaxAggregatorAddr = process.env.AVAX_AGG_ADDRESSS;

  console.log("Deploying contracts with the account: " + deployer.address);

  // Deploy Dataprovider contract
  const Dataprovider = await ethers.getContractFactory("Dataprovider");
  const dataprovider = await Dataprovider.deploy(poolAddr, incentivesAddr, qiTokenAddr, wETHAddr);
  await dataprovider.deployed();
  console.log("Dataprovider deployed to:", dataprovider.address);

  // Deploy Oracle contract
  const Oracle = await ethers.getContractFactory("Oracle");
  oracle = await Oracle.deploy(wAvaxAddr, wEthAddr, avaxAggregatorAddr, wethAggregatorAddr);
  await oracle.deployed();
  console.log("Oracle deployed to:", oracle.address);

  // Deploy Strategy contract
  const Strategy = await ethers.getContractFactory("Strategy");
  strategy = await Strategy.deploy(wAvaxAddr, wEthAddr);
  await strategy.deployed();
  console.log("Strategy deployed to:", strategy.address);

  // Deploy BAToken contract
  const BAToken = await ethers.getContractFactory("BAToken");
  baToken = await BAToken.deploy();
  await baToken.deployed();
  console.log("BAToken deployed to:", baToken.address);

  // Deploy Vault contract
  const Vault = await ethers.getContractFactory("Vault");
  vault = await Vault.deploy(wAvaxAddr, wEthAddr);
  await vault.deployed();
  console.log("Vault deployed to:", vault.address);

  // AAVE LendingPool

  aavePool = await ethers.getContractAt("IAaveLendingPool", aavePoolAddr, signer);
  borrowAsset = await ethers.getContractAt("IERC20", wEthAddr)
  collateralAsset = await ethers.getContractAt("IERC20", wAvaxAddr);

  // Init Strategy contract
  await strategy.initialization(dataprovider.address, oracle.address);

  // Init Vault contract
  await vault.initialization(oracle.address, strategy.address, baToken.address);


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
