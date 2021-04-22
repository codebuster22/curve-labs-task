// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Stoppable.sol";
import "./interface/IStorage.sol";

contract Ballot is Stoppable {
    
    enum BallotState{CREATED, VOTING_STARTED, VOTING_ENDED, RESULTS_OUT}
    
    string public title;
    uint immutable public creation_timestamp;
    BallotState public state;
    
    address immutable voting_storage;
    address immutable voting_controller;
    
    struct Proposal {
        string name;
        string document_hash;
        uint votes;
    }
    Proposal[] public proposals;
    
    mapping(address => uint8) public have_voted;
    
    event BallotContractDeployed(address proposal_address, address storage_address, address controller_address, uint timestamp);
    
    event VotingStarted(address sender, uint timestamp);
    event VotingEnded(address sender, uint timestamp);
    
    event NewVoteCasted(address indexed voter, uint indexed proposal_id, uint vote_count);
    
    constructor (
        address _voting_storage,
        string memory _title,
        uint _creation_timestamp,
        uint8 _state
    ) {
        voting_storage = _voting_storage;
        voting_controller = msg.sender;
        title = _title;
        creation_timestamp = _creation_timestamp;
        state = BallotState(_state);
        emit BallotContractDeployed(address(this), _voting_storage, msg.sender, block.timestamp);
    }
    
    // Add require condition to check for status = CREATED
    function start() public whenStopped {
        require(msg.sender == voting_controller, "Ballot: Sender is not the controller");
       require( proposals.length > 1, "Ballot: Cannot have voting with one proposal" );
        _start();
        state = BallotState.VOTING_STARTED;
        IStorage(voting_storage).changeBallotState(address(this), uint8(BallotState.VOTING_STARTED));
        emit VotingStarted(msg.sender, block.timestamp);
    }
    
    //Add require condition to check for status = VOTING_STARTED
    function end() public whenNotStopped {
        require(msg.sender == voting_controller, "Ballot: Sender is not the controller");
        _stop();
        state = BallotState.VOTING_ENDED;
        IStorage(voting_storage).changeBallotState(address(this), uint8(BallotState.VOTING_ENDED));
        emit VotingEnded(msg.sender, block.timestamp);
    }
    
    function createProposal(string memory _name, string memory _document_hash) public whenStopped {
        require(msg.sender == voting_controller, "Ballot: Sender is not the controller");
        Proposal memory proposal = Proposal(_name, _document_hash, 0);
        proposals.push(proposal);
    }
    
    function createMultipleProposals(string[] memory _proposal_names, string[] memory _proposal_documents) public whenStopped {
        require(msg.sender == voting_controller, "Ballot: Sender is not the controller");
        require(_proposal_names.length == _proposal_documents.length);
        for(uint i; i < _proposal_names.length; i++) {
            proposals.push(
                Proposal({
                    name: _proposal_names[i],
                    document_hash: _proposal_documents[i],
                    votes: 0
                }));
        }
    }
    
    function castVote(uint _id) public whenNotStopped {
        require(have_voted[msg.sender] == 0, "Ballot: You cannot vote multiple times");
        have_voted[msg.sender] = 1;
        uint wt = IStorage(voting_storage).getVoteWeight(msg.sender);
        require(wt>0, "Ballot: You don't have permission to vote");
        proposals[_id].votes+=wt;
        emit NewVoteCasted(msg.sender, _id, proposals[_id].votes);
    }
    
    function destroyBallot() public {
        require(msg.sender == voting_controller, "Ballot: Sender is not the controller");
        _destroyBallot();
    }
    
    function _destroyBallot() private {
        selfdestruct(payable(voting_controller));
    }
    
    // More Useful - can get whole proposal
    function winnerIndex() public view returns (uint winningProposal_) {
        require(uint8(state) >= uint8(BallotState.VOTING_ENDED) , "Ballot: Cannot declare winner without voting");
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].votes > winningVoteCount) {
                winningVoteCount = proposals[p].votes;
                winningProposal_ = p;
            }
        }
    }
    
    function winner() public view returns (string memory winnerName_) {
        require(uint8(state) >= uint8(BallotState.VOTING_ENDED) , "Ballot: Cannot declare winner without voting");
        winnerName_ = proposals[winnerIndex()].name;
    }
    
    function getStorageAddress() external view returns(address storage_) {
        storage_ = voting_storage;
    }
    
    function getControllerAddress() external view returns(address controller_){
        controller_ = voting_controller;
    }
    
    function getAllProposals() external view returns(Proposal[] memory proposals_){
        proposals_ = proposals;
    }
    
}