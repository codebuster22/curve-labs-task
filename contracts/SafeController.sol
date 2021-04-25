// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface ModuleManager{
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success);
    function getOwners()
        external
        view
        returns (address[] memory);
    function isOwner(address owner)
        external
        view
        returns (bool);
}


contract SafeController {
    
    string public constant NAME    = "Safe Ownership Controller";
    string public constant VERSION = "0.1.0";
    
    enum OwnershipProposalAction{REMOVE,ADD}
    
    struct OwnershipProposal{
        address proposedOwner;
        uint proposalId;
        uint newThreshold;
        uint yesWt;
        uint noWt;
        OwnershipProposalAction action;
    }
    
    uint8  public isInitialised;
    uint   public proposalCounter;
    uint24 public constant HALF_WEIGHT = 500000;
    
    ModuleManager private manager;
    address       private controller;
    
    mapping (uint    => OwnershipProposal)         public ownershipProposals;
    mapping (uint    => uint8)                     public proposalStatus;
    mapping (uint    => mapping(address => uint8)) public haveVoted;
    mapping (bytes32 => bool)                      public isExecuted;
    
    event SafeManagerChanged            (address prev_safe, address new_safe);
    event ControlTransferred            (address prev_controller, address new_controller);
    event NewOwnershipProposalCreated   (uint indexed proposal_id, uint8 action, address proposed_owner, uint new_threshold, uint timestamp);
    event OwnershipProposalEnded        (uint indexed proposal_id, uint8 action, bool success, uint timestamp);
    event NewVoteCasted                 (uint indexed proposal_id, uint yes_wt, uint no_wt);
    
    modifier initialisedAndControlled {
        require( isInitialised == 1,       "SafeController: Contract not initialised");
        require( msg.sender == controller, "SafeController: Can only interact using Controller");
        _;
    }
    
    function initialiseSafeController(address _safe, address _controller) external {
        
        require(isInitialised==0, "SafeController: Already initialised");
        isInitialised = 1;
        manager = ModuleManager(_safe);
        controller = _controller;
        
    }
    
    function setController(address _new_controller) external initialisedAndControlled {
        _setController(_new_controller);
    }
    
    function setSafeManager(address _new_safe_manager) external initialisedAndControlled {
        _setSafeManager(_new_safe_manager);
    }
    
    function createOwnershipProposal(uint8 _action, address _proposedOwner, uint _newThreshold) external initialisedAndControlled {
        
        bool flag = manager.isOwner(_proposedOwner);
        require((_action==1 && !flag) || (_action==0 && flag), "SafeController: Invalid Proposal");
        
        uint id = proposalCounter;
        proposalCounter++;
        ownershipProposals[id] = OwnershipProposal(_proposedOwner, id, _newThreshold, 0, 0, OwnershipProposalAction(_action));
        proposalStatus[id] = 1;
        
        emit NewOwnershipProposalCreated(id,_action, _proposedOwner, _newThreshold, block.timestamp);
    }
    
    function yes(uint _proposal_id, uint _yesWt, address _voter) external initialisedAndControlled {
        
        require(proposalStatus[_proposal_id] == 1,    "SafeController: Proposal Ended");
        require(haveVoted[_proposal_id][_voter] == 0, "SafeController: Already casted a vote");
        
        haveVoted[_proposal_id][_voter] = 1;
        uint yesWt = ownershipProposals[_proposal_id].yesWt;
        uint totalWt = yesWt + _yesWt;
        ownershipProposals[_proposal_id].yesWt = totalWt;
        
        emit NewVoteCasted(_proposal_id, totalWt, ownershipProposals[_proposal_id].noWt);
        if(totalWt>HALF_WEIGHT){
            proposalStatus[_proposal_id] = 0;
            _finalise(_proposal_id);
            emit OwnershipProposalEnded(_proposal_id, uint8(ownershipProposals[_proposal_id].action), true, block.timestamp);
        }
    }
    
    function no(uint _proposal_id, uint _noWt, address _voter) external initialisedAndControlled {
        
        require(proposalStatus[_proposal_id] == 1,    "SafeController: Proposal Ended");
        require(haveVoted[_proposal_id][_voter] == 0, "SafeController: Already casted a vote");
        
        haveVoted[_proposal_id][_voter] = 1;
        uint noWt = ownershipProposals[_proposal_id].noWt;
        uint totalWt = noWt + _noWt;
        ownershipProposals[_proposal_id].noWt = totalWt;
        
        emit NewVoteCasted(_proposal_id, ownershipProposals[_proposal_id].yesWt, totalWt);
        if(totalWt>HALF_WEIGHT){
            proposalStatus[_proposal_id] = 0;
            emit OwnershipProposalEnded(_proposal_id, uint8(ownershipProposals[_proposal_id].action), false, block.timestamp);
        }
    }
    
    function getOwners() public view returns(address[] memory owners_) {
        owners_ =  manager.getOwners();
    }
    
    function getController() external view returns(address controller_){
        controller_ = controller;
    }
    
    function getSafeManager() external view returns(address safe_manager_){
        safe_manager_ = address(manager);
    }
    
    function getProposal(uint _proposal_id) public view returns(OwnershipProposal memory proposal_){
        proposal_ = ownershipProposals[_proposal_id];
    }
    
    function getAllActiveProposals() external view returns(OwnershipProposal[] memory proposals_){
        
        OwnershipProposal[] memory proposals = new OwnershipProposal[](proposalCounter);
        
        uint j;
        for(uint i; i<proposalCounter; i++){
            if(proposalStatus[i]==1){
                proposals[j] = ownershipProposals[i];
                j++;
            }
        }
        
        return proposals;
    }
    
    function _setController(address new_controller) private {
        
        require(new_controller != address(0), "SafeController: Cannot abandon any contract");
        require(new_controller != controller, "SafeController: Cannot play double role");
        
        address prev_controller = controller;
        controller = new_controller;
        
        emit ControlTransferred(prev_controller, new_controller);
    }
    
    function _setSafeManager(address new_manager) private {
        
        require(new_manager != address(0), "SafeController: We are not on a break");
        require(new_manager != address(manager), "SafeController: Cannot play double role");
        
        address prev_manager = address(manager);
        manager = ModuleManager(new_manager);
        
        emit SafeManagerChanged(prev_manager, new_manager);
    }
    
    function _getDataHash(bytes memory data)
        private
        pure
        returns (bytes32 dataHash_)
    {
        dataHash_ = keccak256(data);
    }
    
    function _finalise(uint proposal_id) private returns(uint8) {
        
        require(proposalStatus[proposal_id] == 0, "SafeController: Proposal still active");
        
        uint8 action = uint8(ownershipProposals[proposal_id].action);
        address proposedOwner = ownershipProposals[proposal_id].proposedOwner;
        uint newThreshold = ownershipProposals[proposal_id].newThreshold;
        
        if(action == 0){
            _removeOwner(proposedOwner, newThreshold);
            return 1;
        }
        _addOwner(proposedOwner, newThreshold);
        return 1;
    }
    
    function _addOwner(address _newOwner, uint256 _threshold) private {
        bytes memory data = abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", _newOwner, _threshold);
        _executeSafeFunctionTx(data);
    }
    
    function _removeOwner(address _owner, uint256 _threshold) private {
        
        address[] memory owners = getOwners();
        address prevOwner = _getPrevOwner(owners, _owner);
        bytes memory data = abi.encodeWithSignature("removeOwner(address,address,uint256)", prevOwner ,_owner, _threshold);
        _executeSafeFunctionTx(data);
        
    }
    
    function _getPrevOwner(address[] memory owners, address owner) private pure returns(address prevOwner_) {
        
        for(uint i; i<owners.length; i++){
            if(owners[i]==owner){
                prevOwner_ = i==0?address(0x1):owners[i-1];
            }
        }
        
    }
    
    function _executeSafeFunctionTx(bytes memory data) private {
        
        bytes32 dataHash = _getDataHash(data);
        isExecuted[dataHash] = true;
        require(manager.execTransactionFromModule(address(manager), 0, data, Enum.Operation.Call), "Could not execute recovery");
        
    }
    
}