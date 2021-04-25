const fs = require('fs');
const path = require('path');
const hre = require("hardhat");
require('dotenv').config({path: './.env'});
const DeployedContracts = require('../client/src/DeployedContracts.json');
const clientPath = path.resolve(__dirname, '../client/src/');

const {BALANCER_POOL_ADDRESS, SAFE_MANAGER_ADDRESS} = process.env;
console.log(`The Balance Pool address is :- ${BALANCER_POOL_ADDRESS}`);
console.log(`The Safe Manager address is :- ${SAFE_MANAGER_ADDRESS}\n`);

const main = async () => {

    console.log("--------------------------------------------------------------\n")

    console.log("Deploying Controller contract");
    const ControllerFactory = await hre.ethers.getContractFactory("Controller");
    const Controller = await ControllerFactory.deploy();

    const controller =  await Controller.deployed();

    console.log(`Controller deployed to: ${controller.address}\n`);

    console.log("--------------------------------------------------------------\n")

    console.log("Deploying SafeController contract");
    const SafeControllerFactory = await hre.ethers.getContractFactory("SafeController");
    const SafeController = await SafeControllerFactory.deploy();

    const safeController =  await SafeController.deployed();

    console.log(`SafeController deployed to: ${safeController.address}\n`);

    console.log("--------------------------------------------------------------\n")

    console.log("Deploying Storage contract");
    const StorageFactory = await hre.ethers.getContractFactory("Storage");
    const Storage = await StorageFactory.deploy(BALANCER_POOL_ADDRESS, controller.address);

    const storage =  await Storage.deployed();

    console.log(`Storage deployed to: ${storage.address}\n`);

    console.log("--------------------------------------------------------------\n")

    console.log(`Initialising contracts:-`);

    await controller.initialiseController(storage.address, safeController.address);
    await safeController.initialiseSafeController(SAFE_MANAGER_ADDRESS, controller.address);

    console.log(`Successfully Updated!\n`);

    console.log(`Saving contract addresses`);

    let {chainId} = await ethers.provider.getNetwork();

    DeployedContracts[chainId] = DeployedContracts[chainId] || {};
    DeployedContracts[chainId].controller = controller.address;
    DeployedContracts[chainId].storage = storage.address;
    DeployedContracts[chainId].safeController = safeController.address;

    fs.writeFileSync(
      `${clientPath}/DeployedContracts.json`,
      JSON.stringify(DeployedContracts), 
      (err) => {
      if(err) throw err;
    });

    console.log(`Contract Addresses saved`);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });