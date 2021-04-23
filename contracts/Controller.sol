// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ballot.sol";
import "./utils/Administrable.sol";
import "./interface/ISafeController.sol";

// Add function getStorageAddress() - returns storage contract address

contract Controller is Administrable{
    
    string public constant NAME    = "Master Controller";
    string public constant VERSION = "0.1.0";
    
    uint8 public isInitialised;

    IStorage        voting_storage;
    ISafeController safeController;
    
    // ===========================================    Public and External Functions    =================================================================
    
    function initialiseController(address _voting_storage, address _safe) external onlyAdmin{
        isInitialised = 1;
        _setStorage(_voting_storage);
        _setSafeController(_safe);
    }
    
    function setStorage(address _voting_storage) external onlyAdmin {
        _setStorage(_voting_storage);
    }
    
    function setSafeController(address _safe_controller) external onlyAdmin {
        _setSafeController(_safe_controller);
    }
    
    function getSafeController() external view returns(address safe_controller_){
        safe_controller_ = address(safeController);
    }
    
    function getStorage() external view returns(address storage_){
        storage_ = address(voting_storage);
    }
    
    // Implementation of SafeController.sol
    
    function safeCreateOwnershipProposal(
        uint8 _action,
        address _proposedOwner,
        uint _newThreshold
        ) external {
    
        safeController.createOwnershipProposal(_action, _proposedOwner, _newThreshold);
        
    }
    
    function safeYes(uint _proposal_id) external {
        
        uint yesWt = voting_storage.getVoteWeight(msg.sender);
        require( yesWt > 0 , "Controller: No permission to vote" );
        safeController.yes(_proposal_id, yesWt, msg.sender);
        
    }
    
    function safeNo(uint _proposal_id) external {
        
        uint noWt = voting_storage.getVoteWeight(msg.sender);
        require( noWt > 0 , "Controller: No Permission to vote" );
        safeController.no(_proposal_id, noWt, msg.sender);
        
    }
    
    function safeSetController(address _new_controller) external {
        safeController.setController(_new_controller);
    }
    
    function safeSetSafeManager(address _new_safe_manager) external {
        safeController.setSafeManager(_new_safe_manager);
    }
    
    function safeGetSafeManager() external view returns(address safe_manager_){
        safe_manager_ = safeController.getSafeManager();
    }
    
    function safeGetController() external view returns(address controller_){
        controller_ = safeController.getController();
    }
    
    // End of SafeController.sol Implementation
    
    
    // Implementation of Storage.sol
    
    function storageRegisterVoter(string memory _name) external {
        
        require( voting_storage.is_voter( _msgSender()) == 0 , "Controller: Registered as a Voter" );
        voting_storage.registerVoter( _msgSender() , _name );
        
    }
    
    function storageSetController(address _new_controller) external onlyAdmin {
        voting_storage.setController(_new_controller);
    }
    
    // End of Storage.sol Implementation
    
    
    // Implementation of Ballot.sol
    
    function ballotCreateBallot(string memory _title) external onlyAdmin {
        
        Ballot ballot = new Ballot(address(voting_storage),_title, block.timestamp, 0);
        voting_storage.createBallot(address(ballot), _title);
    }
    
    function ballotCancelBallot(uint _ballot_id) external onlyAdmin {
        
        address ballot_address;
        (ballot_address, )= voting_storage.getBallot(_ballot_id);
        Ballot(ballot_address).destroyBallot();
        voting_storage.cancelBallot(_ballot_id);
        
    }
    
    function ballotStart(uint _ballot_id) external onlyAdmin {
        
        address ballot_address;
        (ballot_address, )= voting_storage.getBallot(_ballot_id);
        Ballot(ballot_address).start();
        
    }
    
    function ballotEnd(uint _ballot_id) external onlyAdmin {
        
        address ballot_address;
        (ballot_address, )= voting_storage.getBallot(_ballot_id);
        Ballot(ballot_address).end();
        
    }
    
    function ballotCreateProposals(
        address _ballot_address,
        string[] memory _proposal_names, 
        string[] memory _proposal_documents
        ) external onlyAdmin {
            
        Ballot( _ballot_address ).createProposals( _proposal_names , _proposal_documents );
        
    }
    
    function ballotCastVote(address _ballot_address, uint _proposal_id) external {
        Ballot(_ballot_address).castVote(_proposal_id);
    }
    
    
    // End of Ballot.sol Implementation
    
    
    // ===========================================    Private and Internal Functions    =================================================================
    
    function _setStorage(address _voting_storage) private {
        
        require(_voting_storage != address(0), "Controller: Address is zero address");
        voting_storage = IStorage(_voting_storage);
        
    }
    
    function _setSafeController(address _safe) private {
        
        require(_safe != address(0), "Controller: Address is zero address");
        safeController = ISafeController(_safe);
        
    }

}