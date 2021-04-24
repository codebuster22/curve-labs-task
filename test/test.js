const { expect } = require('chai');
const { ethers } = require('hardhat');
require('dotenv').config({path: './.env'});

const BALANCER_POOL = process.env.BALANCER_POOL_ADDRESS;
const SAFE_MANAGER  = process.env.SAFE_MANAGER_ADDRESS;

const deploy = async () => {

    const setup = {};

    const StorageFactory        = await ethers.getContractFactory('Storage');
    const ControllerFactory     = await ethers.getContractFactory('Controller');
    const SafeControllerFactory = await ethers.getContractFactory('SafeController');
    setup.BallotFactory         = await ethers.getContractFactory('Ballot');

    const Controller     = await ControllerFactory.deploy();
    setup.controller     = await Controller.deployed();

    const SafeController = await SafeControllerFactory.deploy();
    setup.safeController = await SafeController.deployed();

    const Storage        = await StorageFactory.deploy(BALANCER_POOL, setup.controller.address);
    setup.storage        = await Storage.deployed();

    await setup.controller.initialiseController(setup.storage.address, setup.safeController.address);
    await setup.safeController.initialiseSafeController(SAFE_MANAGER, setup.controller.address);

    return setup;
}

describe('Voting App', async () => {

    console.log("Running controller test");

    const [defaultAccount, account1, account2] = await ethers.getSigners();

    let setup;

    beforeEach(async ()=> {
        setup = await deploy();
    });

    describe('Initialisation', () => {
        it('>> should have Storage set at Controller',async ()=> {
            const {controller, storage} = setup;
            expect(await controller.getStorage()).to.be.equal(storage.address);
        });

        it('>> should have SafeController set at Controller', async () => {
            const {controller, safeController} = setup;
            expect(await controller.getSafeController()).to.be.equal(safeController.address);
        });

        it('>> should have Controller set at Storage', async () => {
            const {controller, storage} = setup;
            expect(await storage.getController()).to.be.equal(controller.address);
        });

        it('>> should have Balancer Pool set at Storage', async () => {
            const {storage} = setup;
            expect(await storage.bpool()).to.be.equal(BALANCER_POOL);
        });

        it('>> should have Controller set at SafeController', async () => {
            const {controller, safeController} = setup;
            expect(await safeController.getController()).to.be.equal(controller.address);
        });

        it('>> should have Balancer Pool set at Storage', async () => {
            const {safeController} = setup;
            expect(await safeController.getSafeManager()).to.be.equal(SAFE_MANAGER);
        });

        it('>> should have zero voters registered', async () => {
            const {storage} = setup;
            expect(await storage.voter_count()).to.be.equal(0);
        });

        it('>> should have zero ballots created', async () => {
            const {storage} = setup;
            expect(await storage.ballot_count()).to.be.equal(0);
        });

        it('>> should have zero proposals at SafeManager', async () => {
            const {safeController} = setup;
            expect(await safeController.proposalCounter()).to.be.equal(0);
        });
    });

    describe('Interaction with ballots', () => {
        it('>> should create new ballot contract',async () => {
            const {controller, storage, BallotFactory} = setup;
            const AGENDA = "Corona Innovation";
            await controller.ballotCreateBallot(AGENDA);
            const ballotDetails = await storage.getBallot(0);
            const ballot        = await BallotFactory.attach(ballotDetails.contract_address);
            expect(ballotDetails.title).to.be.equal(AGENDA);
            expect(await ballot.title()).to.be.equal(AGENDA);
        });

        it('>> should create new proposals', async () => {
            const {controller, storage, BallotFactory} = setup;
            const AGENDA             = "Corona Innovation";
            const PROPOSALS          = ["P1", "P2"];
            const PROPOSAL_DOCUMENTS = ["D1", "D2"];

            await controller.ballotCreateBallot(AGENDA);

            const contract_address = await storage.getBallotAddress(0);
            const ballot = await BallotFactory.attach(contract_address);

            await controller.ballotCreateProposals(contract_address, PROPOSALS, PROPOSAL_DOCUMENTS);
            const proposals = await ballot.getAllProposals();

            proposals.map(
                ({name, document_hash}, index) => {
                    expect(name).to.be.equal(PROPOSALS[index]);
                    expect(document_hash).to.be.equal(PROPOSAL_DOCUMENTS[index]);
                }
            )
        });

        it('>> should start voting process', async () => {
            const {controller,storage, BallotFactory} = setup;
            const AGENDA             = "Corona Innovation";
            const PROPOSALS          = ["P1", "P2"];
            const PROPOSAL_DOCUMENTS = ["D1", "D2"];

            await controller.ballotCreateBallot(AGENDA);
            const contract_address = await storage.getBallotAddress(0);
            const ballot           = await BallotFactory.attach(contract_address);
            await controller.ballotCreateProposals(contract_address, PROPOSALS, PROPOSAL_DOCUMENTS);
            await controller.ballotStart(0);
            expect(await ballot.state()).to.be.equal(1);
        });

        it('>> should end voting process', async () => {
            const {controller,storage, BallotFactory} = setup;
            const AGENDA             = "Corona Innovation";
            const PROPOSALS          = ["P1", "P2"];
            const PROPOSAL_DOCUMENTS = ["D1", "D2"];

            await controller.ballotCreateBallot(AGENDA);
            const contract_address = await storage.getBallotAddress(0);
            const ballot           = await BallotFactory.attach(contract_address);
            await controller.ballotCreateProposals(contract_address, PROPOSALS, PROPOSAL_DOCUMENTS);
            await controller.ballotStart(0);
            await controller.ballotEnd(0);
            expect(await ballot.state()).to.be.equal(3);
        });
    });

    describe('Admin interaction with controller', () => {
        it('>> should add new admin', async () => {
            const {controller} = setup;
            await controller.addAdmin(account1.address);
            expect(await controller.checkIsAdmin(account1.address)).to.be.equal(1);
        });

        it('>> should revert when accessed by non admin', async () => {
            const {controller} = setup;
            try{
                await controller.connect(account1).addAdmin(account2.address);
            } catch (error) {
                if(error.data.name!== 'RuntimeError') return process(-1);
            }
            expect(await controller.checkIsAdmin(account1.address)).to.be.equal(0);
        });

        it('>> can resign as admin', async () => {
            const {controller} = setup;
            await controller.addAdmin(account1.address);
            await controller.resignAsAdmin();
            expect(await controller.checkIsAdmin(defaultAccount.address)).to.be.equal(0);
        });

        it('>> cannot allow last admin to resign', async () => {
            const {controller} = setup;
            try{
                await controller.resignAsAdmin();
            }catch (error) {
                if(error.data.name!== 'RuntimeError') return process(-1);
            }
            expect(await controller.checkIsAdmin(defaultAccount.address)).to.not.be.equal(0);
        });
    });

})