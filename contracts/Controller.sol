// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Administrable.sol";
import "./Ballot.sol";

// Add function getStorageAddress() - returns storage contract address

contract Controller is Administrable{

    address voting_storage;
    
    constructor (address _voting_storage) {
        _setStorage(_voting_storage);
    }
    
    function setStorage(address _voting_storage) external onlyAdmin {
        _setStorage(_voting_storage);
    }
    
    function _setStorage(address _voting_storage) private {
        voting_storage = _voting_storage;
    }
    
    // Can remove this function, can directly interact with Storage.sol
    function registerVoter(string memory _name) public {
        
        require( IStorage(voting_storage).is_voter(_msgSender()) == 0 , "VotingMain: Already Registered as a Voter" );
        IStorage(voting_storage).registerVoter(_msgSender(), _name);
        
    }
    
    function start(uint _ballot_id) public onlyAdmin {
        address ballot_address;
        (ballot_address, )= IStorage(voting_storage).getBallot(_ballot_id);
        Ballot(ballot_address).start();
    }
    
    function end(uint _ballot_id) public onlyAdmin {
        address ballot_address;
        (ballot_address, )= IStorage(voting_storage).getBallot(_ballot_id);
        Ballot(ballot_address).end();
    }

    function createBallot(string memory _title) public onlyAdmin {
        
        Ballot ballot = new Ballot(address(voting_storage),_title, block.timestamp, 0);
        
        IStorage(voting_storage).createBallot(address(ballot), _title);
    }
    
    function cancelBallot(uint _ballot_id) public onlyAdmin {
        address ballot_address;
        (ballot_address, )= IStorage(voting_storage).getBallot(_ballot_id);
        Ballot(ballot_address).destroyBallot();
        IStorage(voting_storage).cancelBallot(_ballot_id);
    }
    
    function createProposal(uint _ballot_id, string memory _proposal_name, string memory _proposal_document) public onlyAdmin {
        address ballot_address;
        (ballot_address, )= IStorage(voting_storage).getBallot(_ballot_id);
        Ballot(ballot_address).createProposal(_proposal_name, _proposal_document);
    }
    
    function createMultipleProposals(uint _ballot_id, string[] memory _proposal_names, string[] memory _proposal_documents) public onlyAdmin {
        address ballot_address;
        (ballot_address, )= IStorage(voting_storage).getBallot(_ballot_id);
        Ballot(ballot_address).createMultipleProposals(_proposal_names, _proposal_documents);
    }
    
    function setStorageController(address _new_controller) public onlyAdmin {
        IStorage(voting_storage).setController(_new_controller);
    }
    
    // Read only functions
    
    function getBallot(uint _id) external view returns(address ballot_address_, string memory title_){
        return IStorage(voting_storage).getBallot(_id);
    }

    // Need more details about ballot, and status[] also
    function getAllBallots() external view returns(address[] memory , string[] memory ){
        return IStorage(voting_storage).getAllBallots();
    }

    function getStorage() external view returns(address storage_){
        storage_ = voting_storage;
    }

}