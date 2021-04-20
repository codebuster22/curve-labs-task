// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Administrable.sol";
import "./Stoppable.sol";

contract VotingMain is Administrable, Stoppable{

    struct Candidate{
        uint id;
        string name;
        address account;
        uint vote_count;
    }
    mapping(uint => Candidate) public id_to_candidate;
    mapping(address => uint) public address_to_candidate_id;
    mapping(address => uint8) public is_candidate;
    uint public candidate_count;
    
    event NewCandidateAdded(address indexed candidate, uint candidate_id, string candidate_name, uint timestamp);
    event CandidateResigned(address indexed candidate, uint indexed candidate_id ,string candidate_name, uint timestamp);
    
    struct Voter{
        uint id;
        string name;
        address account;
        uint vote_wt;
    }
    mapping(uint => Voter) public id_to_voter;
    mapping(address => uint) public address_to_voter_id;
    mapping(address => uint8) public is_voter;
    uint public voter_count;
    
    event NewVoterAdded(address indexed voter, uint voter_id, string voter_name, uint timestamp);
    
    event NewVoteCasted(address indexed voter, uint indexed candidate_id, string candidate_name, uint vote_count);
    
    event VotingStarted(address sender, uint timestamp);
    event VotingEnded(address sender, uint timestamp);
    
    function start() public onlyAdmin {
        require( candidate_count > 1, "VotingMain: Cannot have election with one candidate" );
        _start();
        emit VotingStarted(msg.sender, block.timestamp);
    }
    
    function end() public onlyAdmin {
        _stop();
        emit VotingEnded(msg.sender, block.timestamp);
    }
    
    function registerVoter(string memory _name) public whenStopped {
        
        require( is_voter[_msgSender()] == 0 , "VotingMain: Already Registered as a Voter" );
        
        id_to_voter[voter_count] = Voter(voter_count, _name, _msgSender(), 1);
        address_to_voter_id[_msgSender()] = voter_count;
        is_voter[_msgSender()] = 1;
        
        emit NewVoterAdded(_msgSender(), voter_count, _name, block.timestamp);
        voter_count++;
    }
    
    function cast_vote(uint _candidate_id) public whenNotStopped {
        
        require( is_voter[_msgSender()] == 1 , "VotingMain: You are not registered as Voter" );
        require( id_to_voter[ address_to_voter_id[_msgSender()] ].vote_wt > 0, "VotingMain: Not enough weight for voting" );
        require(id_to_candidate[_candidate_id].account != address(0), "VotingMain: Voldemort doesn't require any vote (Candidate doesn't exists");
        
        id_to_candidate[_candidate_id].vote_count++;
        id_to_voter[ address_to_voter_id[_msgSender()] ].vote_wt--;
        
        emit NewVoteCasted(
            msg.sender,
            _candidate_id,
            id_to_candidate[_candidate_id].name,
            id_to_candidate[_candidate_id].vote_count)
            ;
    }

    function addCandidate(string memory _name) public whenStopped {
        
        require( is_candidate[_msgSender()] == 0 ,"VotingMain: Already Registered as a Candidate");
        
        id_to_candidate[candidate_count] = Candidate(candidate_count, _name, msg.sender, 0);
        address_to_candidate_id[_msgSender()] = candidate_count;
        is_candidate[_msgSender()] = 1;
        
        emit NewCandidateAdded(msg.sender, candidate_count, _name, block.timestamp);
        candidate_count++;
    }
    
    function resignCandidate() public whenStopped {
        
        require( is_candidate[_msgSender()] == 1 , "VotingMain: You are not a candidate.");
        
        uint id = address_to_candidate_id[_msgSender()];
        
        emit CandidateResigned(_msgSender(), id, id_to_candidate[id].name, block.timestamp);
        
        delete id_to_candidate[ id ];
        delete address_to_candidate_id[_msgSender()];
        delete is_candidate[_msgSender()];
        candidate_count--;
    }
    
    
    
    // Read only functions
    
    function getCandidate(uint _id) external view returns(string memory name_, uint vote_count_){
        return (
            id_to_candidate[_id].name,
            id_to_candidate[_id].vote_count
            );
    }

    function getAllCandidate() external view returns(string[] memory , uint[] memory ){
        string[] memory candidates_ = new string[](candidate_count);
        uint[] memory total_votes_ = new uint[](candidate_count);
        for(uint i; i<candidate_count; i++){
            candidates_[i] = id_to_candidate[i].name;
            total_votes_[i] = id_to_candidate[i].vote_count;
        }
        return (candidates_, total_votes_);
    }

}