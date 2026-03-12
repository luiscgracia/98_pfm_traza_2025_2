async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Desplegando contrato con la cuenta:", deployer.address);

    const Contract = await ethers.getContractFactory("SupplyChainTracker");
    const contract = await Contract.deploy();

    console.log("Contrato desplegado en la dirección:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });