const hre = require("hardhat");
require('dotenv').config({path: './.env'});
const fs = require('fs');


const {BALANCER_POOL_ADDRESS} = process.env;

console.log(`The Balance Pool address is :- ${BALANCER_POOL_ADDRESS}\n`);

const main = async () => {

    console.log("--------------------------------------------------------------\n")

    console.log("Deploying Storage contract");
    const Storage = await hre.ethers.getContractFactory("Storage");
    const storage = await Storage.deploy(BALANCER_POOL_ADDRESS);

    const storageInstance =  await storage.deployed();

    console.log(`Storage deployed to: ${storage.address}\n`);

    console.log("--------------------------------------------------------------\n")

    console.log("Deploying Controller contract");
    const Controller = await hre.ethers.getContractFactory("Controller");
    const controller = await Controller.deploy(storage.address);

    const controllerInstance =  await controller.deployed();

    console.log(`Controller deployed to: ${controller.address}\n`);

    console.log("--------------------------------------------------------------\n")

    console.log(`Updating Controller:-`);

    await storageInstance.initialiseController(controller.address);

    const addCont = await storageInstance.getController();
    const addStor = await controllerInstance.getStorage();

    if(addCont === controller.address && addStor === storage.address) console.log("Successfully Updated");

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });