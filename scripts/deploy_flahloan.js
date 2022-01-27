async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const flashloan = await ethers.getContractFactory("Myflashloan");
    const flashloanContract = await flashloan.deploy("0x7fdC1FdF79BE3309bf82f4abdAD9f111A6590C0f");

    console.log("flashloan address:", flashloanContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });