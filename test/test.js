const { expect, assert } = require("chai");
const { ethers } = require("hardhat");


// Fuji AAVE lending pool : 0x76cc67FF2CC77821A70ED14321111Ce381C2594D
// Fuji AAVE incentives controller : 0xa1EF206fb9a8D8186157FC817fCddcC47727ED55
// Fuji WETH : 0x9668f5f55f2712Dd2dfa316256609b516292D554
// Fuji WAVAX : 0xd00ae08403B9bbb9124bB305C09058E32C39A48c

const poolAddr = "0x76cc67FF2CC77821A70ED14321111Ce381C2594D";
const incentivesAddr = "0xa1EF206fb9a8D8186157FC817fCddcC47727ED55";
const qiToken = "0xe401e9ce0e354ad9092a63ee1dfa3168bb83f3da";
const wEthAddr = "0x9668f5f55f2712Dd2dfa316256609b516292D554";
const wAvaxAddr = "0xd00ae08403B9bbb9124bB305C09058E32C39A48c";
const wethAggregatorAddr = "0x86d67c3D38D2bCeE722E601025C25a575021c6EA";
const avaxAggregatorAddr = "0x5498BB86BC934c8D34FDA08E81D444153d0D06aD";
const aavePoolAddr = "0x76cc67FF2CC77821A70ED14321111Ce381C2594D";

describe("BorrowingAGG", function () {

    let dataprovider;
    let oracle;
    let strategy;
    let aavePool;

    beforeEach(async () => {
        // Get a signer
        const signer = await ethers.provider.getSigner(0);

        // Deploy Dataprovider contract
        const Dataprovider = await ethers.getContractFactory("Dataprovider");
        dataprovider = await Dataprovider.deploy(poolAddr, incentivesAddr, qiToken, wEthAddr);
        await dataprovider.deployed();

        // Deploy Oracle contract
        const Oracle = await ethers.getContractFactory("Oracle");
        oracle = await Oracle.deploy(wAvaxAddr, wEthAddr, avaxAggregatorAddr, wethAggregatorAddr);
        await oracle.deployed();

        // Deploy Strategy contract
        const Strategy = await ethers.getContractFactory("Strategy");
        strategy = await Strategy.deploy(wAvaxAddr, wEthAddr);
        await strategy.deployed();

        // Deploy BAToken contract
        const BAToken = await ethers.getContractFactory("BAToken");
        baToken = await BAToken.deploy();
        await baToken.deployed();

        // Deploy Vault contract
        const Vault = await ethers.getContractFactory("Vault");
        vault = await Vault.deploy(wAvaxAddr, wEthAddr);
        await vault.deployed();

        // AAVE LendingPool
        aavePool = await ethers.getContractAt("IAaveLendingPool", aavePoolAddr, signer);
        borrowAsset = await ethers.getContractAt("IERC20", wEthAddr)
        collateralAsset = await ethers.getContractAt("IERC20", wAvaxAddr);

        // Init Strategy contract
        await strategy.initialization(dataprovider.address, oracle.address);

        // Init Vault contract
        await vault.initialization(oracle.address, strategy.address, baToken.address);


    });

    it("Aave Rates", async function() {


    })

    it("Deposit", async function () {
        const [user] = await ethers.getSigners();
        const amountToDeposit = 100;

        await vault.connect(user).deposit(amountToDeposit, { value: amountToDeposit });

        const balanceVault = await ethers.provider.getBalance(vault.address);
        const balanceCollateralBAToken = await vault.getDebtCollateralToken();
        console.log("Balance contract :", balanceVault.toString());
        console.log("Balance BAToken :", balanceCollateralBAToken.toString());

        assert.equal(amountToDeposit.toString(), balanceVault.toString(), balanceCollateralBAToken.toString());
    });
    //
    // it("Deposit & Withdraw", async function () {
    //     const [user] = await ethers.getSigners()
    //     const amountToDeposit = 100;
    //     const amountToWithdraw = 25;
    //
    //     await vault.connect(user).deposit(amountToDeposit, { value: amountToDeposit });
    //     await vault.connect(user).withdraw(amountToWithdraw);
    //
    //     const balanceVault = await ethers.provider.getBalance(vault.address);
    //     const balanceCollateralBAToken = await vault.getDebtCollateralToken();
    //     const balanceBorrowBAToken = await vault.getDebtBorrowToken();
    //     console.log("Balance contract :", balanceVault.toString());
    //     console.log("Balance collateral BAToken :", balanceCollateralBAToken.toString());
    //     console.log("Balance borrow BAToken :", balanceBorrowBAToken.toString());
    //
    //     assert.equal((amountToDeposit - amountToWithdraw).toString(), balanceVault.toString(), balanceCollateralBAToken.toString());
    // });
    //
    // it("Deposit to AAVE", async function () {
    //     const [user] = await ethers.getSigners()
    //
    //     const amountToDeposit = 100;
    //     await vault.connect(user).deposit(amountToDeposit, { value: amountToDeposit });
    //
    //     const balanceVaultBefore = await ethers.provider.getBalance(vault.address);
    //     const balanceCollateralBAToken = await vault.getDebtCollateralToken();
    //     console.log("Balance contract before :", balanceVaultBefore.toString());
    //     console.log("Balance BAToken :", balanceCollateralBAToken.toString());
    //
    //     const amountToDepositToAAVE = 25;
    //     //await aavePool.connect(user).deposit(avaxAddr, amountToDepositToAAVE, vault.address, 0, {value : amountToDepositToAAVE});
    //     await vault.connect(user)._lendFromProtocol(amountToDepositToAAVE, 0);
    //
    //     const balanceVaultAfter = await ethers.provider.getBalance(vault.address);
    //     const balanceAAVE = aavePool.getUserAccountData(user.address);
    //     console.log("Balance contract before :", balanceVaultAfter.toString());
    //     console.log("AAVE vault data :", balanceAAVE.toString());
    //
    //     assert.equal(balanceVaultBefore.toString(), balanceVaultAfter.add(amountToDepositToAAVE).toString());
    // });

});
