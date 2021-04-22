// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// 0x1A7F38418aF5AaBF0fcAe420Ea0b9BbF7bBfd34b

interface IBPool{
    function balanceOf(address whom) external view returns (uint);
    function totalSupply() external view returns (uint);
}

contract Storage{
    
    uint constant public weightDecimals = 4;
    
    enum BallotState{CREATED, VOTING_STARTED, VOTING_ENDED, RESULTS_OUT}
    
    struct Ballot{
        uint id;
        string title;
        address contract_address;
        BallotState ballot_state;
    }
    mapping(uint => Ballot) public id_to_ballot;
    mapping(address => uint) public address_to_ballot_id;
    mapping(address => uint8) public is_ballot_contract;
    uint public ballot_count;
    
    event NewBallotCreated(address indexed creator, address ballot_address, uint ballot_id, string ballot_for, uint timestamp);
    event BallotCancelled(address indexed canceller,address ballot_address, uint indexed ballot_id, string ballot_for, uint timestamp);
    event BallotStateChanged(address indexed ballot_address, uint indexed ballot_id, uint8 status, uint timestamp);
    
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
    
    event ControllerChanged(address indexed prev_controller, address indexed new_controller, uint timestamp);
    
    address inital_controller;
    address voting_controller;
    uint8 is_controller_set;
    
    IBPool public bpool;
    
    modifier onlyController() {
        require(msg.sender == voting_controller, "Storage: Only controller can execute this.");
        _;
    }
    
    constructor (address _pool) {
        inital_controller = msg.sender;
        bpool = IBPool(_pool);
    }
    
    function _getWeight(address provider) private view returns(uint){
        return bpool.balanceOf(provider);
    }
    
    function _totalSupply() private view returns(uint) {
        return bpool.totalSupply();
    }
    
    function _calculateWeight(address provider) private view returns(uint share) {
        uint weight = _getWeight(provider);
        uint supply = _totalSupply();
        
        share = (weight*1000000)/supply;
    }
    
    function registerVoter(address _voter, string memory _name) public returns(uint8 flag_) {
        
        // Add this to remove function from controller 
        // require(  msg.sender == _voter, "Storage: Need to register using same address" );
        // require( is_voter(_voter) == 0 , "Storage: Already Registered as a Voter" );
        uint id = voter_count;
        voter_count++;
        
        is_voter[_voter] = 1;
        address_to_voter_id[_voter] = id;
        
        uint voteWeight = _calculateWeight(_voter);
        id_to_voter[id] = Voter(id, _name, _voter, voteWeight);
        
        emit NewVoterAdded(_voter, id, _name, block.timestamp);
        return 1;
    }
    
    function createBallot(address _ballot_address, string memory _title) external onlyController returns(uint8 flag_) {
        
        uint id = ballot_count;
        ballot_count++;
        
        id_to_ballot[id] = Ballot(id, _title, _ballot_address, BallotState.CREATED);
        address_to_ballot_id[_ballot_address] = id;
        is_ballot_contract[_ballot_address] = 1;
        
        emit NewBallotCreated(msg.sender, _ballot_address, id, _title, block.timestamp);
        return 1;
    }
    
    function cancelBallot(uint _ballot_id) public onlyController returns(uint8 flag_){
        
        ballot_count--;
        
        string memory title = id_to_ballot[_ballot_id].title;
        address contract_address = id_to_ballot[_ballot_id].contract_address;
        
        delete id_to_ballot[_ballot_id];
        delete address_to_ballot_id[contract_address];
        delete is_ballot_contract[contract_address];
        
        emit BallotCancelled(msg.sender,contract_address, _ballot_id, title, block.timestamp );
        return 1;
    }
    
    function changeBallotState(address _ballot_address, uint8 _new_state) public returns(uint8 flag_) {
        require(is_ballot_contract[_ballot_address] == 1, "Storage: Invalid Ballot Address");
        require(msg.sender == _ballot_address, "Storage: Ballot can only change it's own state");
        uint id = address_to_ballot_id[_ballot_address];
        id_to_ballot[id].ballot_state = BallotState(_new_state);
        emit BallotStateChanged(msg.sender, id, _new_state, block.timestamp);
        return 1;
    }
    
    function initialiseController(address _controller) public {
        require(is_controller_set == 0, "Storage: Can only be called once.");
        require(_controller != address(0), "Storage: Controller cannot be set to zero address.");
        require(_controller != address(this), "Storage: This contract is not eligible for controlling itself");
        require(_controller != msg.sender, "Storage: new controller is same as previous controller");
        is_controller_set = 1;
        _setController(_controller);
        emit ControllerChanged(address(0), _controller, block.timestamp);
    }
    
    function setController(address _new_controller) public onlyController {
        require(_new_controller != address(0), "Storage: Controller cannot be set to zero address.");
        require(_new_controller != address(this), "Storage: This contract is not eligible for controlling itself");
        require(_new_controller != msg.sender, "Storage: new controller is same as previous controller");
        _setController(_new_controller);
        emit ControllerChanged(msg.sender, _new_controller, block.timestamp);
    }
    
    function _setController(address _new_controller) private {
        voting_controller = _new_controller;
    }
    
    
    function getController() external view returns(address controller_) {
        controller_ = voting_controller;
    }
    
    function getBallot(uint _ballot_id) external view returns(address ballot_address_, string memory title_){
        ballot_address_ = id_to_ballot[_ballot_id].contract_address;
        title_ = id_to_ballot[_ballot_id].title;
    }
    
    function getVoteWeight(address _voter) external view returns(uint wt_){
        require(is_voter[_voter] == 1, "Storage: Not a voter");
        wt_ = id_to_voter[address_to_voter_id[_voter]].vote_wt;
    }
    
    // Need more details about ballot and status[] also
    function getAllBallots() external view returns(address[] memory , string[] memory ){
        address[] memory ballot_addresses = new address[](ballot_count);
        string[] memory titles = new string[](ballot_count);
        for(uint i; i<ballot_count; i++){
            ballot_addresses[i] = id_to_ballot[i].contract_address;
            titles[i] = id_to_ballot[i].title;
        }
        return (ballot_addresses, titles);
    }
    
}