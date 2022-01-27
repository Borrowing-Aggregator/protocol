async function main() {
    const addr = process.env.FLASHLOAN_CONTRACT_ADDRESS;
    const Myflashloan = await hre.ethers.getContractAt("Myflashloan", addr);
    // Take flashloan 
    await Myflashloan.flashloan("0xd00ae08403B9bbb9124bB305C09058E32C39A48c")
    console.log("Took a flashloan of 1 WAVAX and payed it back ");



}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });