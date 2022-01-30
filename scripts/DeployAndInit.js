async function main() {

    // Variables
    const wEthAddr = process.env.WETH_ADDRESS;
    const wAvaxAddr = process.env.WAVAX_ADDRESS;

    const oracleAddr = process.env.ORACLE_ADDRESS;
    const strategyAddr = process.env.STRATEGY_ADDRESS;
    const baTokenAddr = process.env.BATOKEN_ADDRESS;
    const aavePoolAddr = process.env.AAVEPOOL_ADDRESS;
    const qiAvaxAddr = process.env.QIAVAX_ADDRESS;
    const qiComptrollerAddr = process.env.QICOMPTROLLER_ADDRESS;

    // Signer
    const [signer] = await ethers.getSigners();
    console.log("Hardhat connected to: ", signer.address);

    // Deploy Vault contract
    const Vault = await ethers.getContractFactory("Vault");
    vault = await Vault.deploy(wAvaxAddr, wEthAddr);
    await vault.deployed();
    console.log("Vault deployed to:", vault.address);

    // Init Vault contract
    await vault.initialization(
        oracleAddr,
        strategyAddr,
        baTokenAddr,
        aavePoolAddr,
        qiAvaxAddr,
        qiComptrollerAddr
    );
    console.log("Vault contract initialized");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
