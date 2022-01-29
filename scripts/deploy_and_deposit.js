
// Variables
const aavePoolAddr = '0x76cc67FF2CC77821A70ED14321111Ce381C2594D';
const aaveIncentivesAddr = '0xa1EF206fb9a8D8186157FC817fCddcC47727ED55';
const qiTokenAddr = '0xe401e9ce0e354ad9092a63ee1dfa3168bb83f3da';
const wEthAddr = '0x9668f5f55f2712Dd2dfa316256609b516292D554';
const wAvaxAddr = '0xd00ae08403B9bbb9124bB305C09058E32C39A48c';
const wethAggregatorAddr = '0x86d67c3D38D2bCeE722E601025C25a575021c6EA';
const avaxAggregatorAddr = '0x5498BB86BC934c8D34FDA08E81D444153d0D06aD';


async function deployAll() {

  // Deploy Dataprovider contract
  const Dataprovider = await ethers.getContractFactory("Dataprovider");
  const dataprovider = await Dataprovider.deploy(aavePoolAddr, aaveIncentivesAddr, qiTokenAddr, wEthAddr);
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
  const vault = await Vault.deploy(wAvaxAddr, wEthAddr);
  await vault.deployed();
  console.log("Vault deployed to:", vault.address);

  // Init Vault contract
  await vault.initialization(oracle.address, strategy.address, baToken.address);
  console.log("Vault contract initialized");

  // Init Strategy contract
  await strategy.initialization(dataprovider.address, oracle.address);
  console.log("Strategy contract initialized");

  return vault
}

async function main() {

  // Signer
  const [signer] = await ethers.getSigners();
  console.log("Hardhat connected to: ", signer.address);

  // Init contracts
  const vault = await deployAll()

  // Deposit
  const deposit = "0";
  const amountToDeposit = await ethers.utils.parseEther(deposit);
  await vault.deposit(amountToDeposit)

  // Metrics
  const balanceVault = await ethers.provider.getBalance(vault.address);
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
