// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// 0x1A7F38418aF5AaBF0fcAe420Ea0b9BbF7bBfd34b

interface IBPool{
    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
}

contract Storage{
    
    enum BallotState{CREATED, VOTING_STARTED, VOTING_ENDED, RESULTS_OUT}
    
    string public constant NAME    = "Storage";
    string public constant VERSION = "0.1.0";
    
    uint   public constant weightDecimals = 4;
    uint   public ballot_count;
    uint   public voter_count;
    
    address voting_controller;
    
    IBPool public bpool;
    
    struct Ballot{
        uint id;
        BallotState ballot_state;
        address contract_address;
        string title;
    }
    
    struct Voter{
        uint id;
        uint vote_wt;
        address account;
        string name;
    }
    
    mapping (uint    => Ballot) public id_to_ballot;
    mapping (address => uint)   public address_to_ballot_id;
    mapping (address => uint8)  public is_ballot_contract;
    mapping (uint    => Voter)  public id_to_voter;
    mapping (address => uint)   public address_to_voter_id;
    mapping (address => uint8)  public is_voter;
    
    event NewBallotCreated      (address indexed creator, address ballot_address, uint ballot_id, string ballot_for, uint timestamp);
    event BallotCancelled       (address indexed canceller,address ballot_address, uint indexed ballot_id, string ballot_for, uint timestamp);
    event BallotStateChanged    (address indexed ballot_address, uint indexed ballot_id, uint8 status, uint timestamp);
    event NewVoterAdded         (address indexed voter, uint voter_id, string voter_name, uint timestamp);
    event ControllerChanged     (address indexed prev_controller, address indexed new_controller, uint timestamp);
    
    modifier onlyController() {
        require( msg.sender == voting_controller, "Storage: Only controller can execute this." );
        _;
    }
    
    modifier onlyBallot() {
        require( is_ballot_contract[msg.sender] == 1, "Storage: Only ballot can change it's state" );
        _;
    }
    
    constructor (address _pool, address _controller) {
        bpool = IBPool(_pool);
        _setController(address(0),_controller);
    }
    
    function registerVoter(address _voter, string memory _name) public onlyController returns(uint8 flag_) {
        
        uint id = voter_count;
        voter_count++;
        
        is_voter[_voter] = 1;
        address_to_voter_id[_voter] = id;
        uint voteWeight = _calculateWeight(_voter);
        id_to_voter[id] = Voter(id, voteWeight, _voter, _name);
        
        emit NewVoterAdded(_voter, id, _name, block.timestamp);
        return 1;
    }
    
    function createBallot(address _ballot_address, string memory _title) external onlyController returns(uint8 flag_) {
        
        uint id = ballot_count;
        ballot_count++;
        
        id_to_ballot[id] = Ballot(id,BallotState.CREATED, _ballot_address, _title );
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
    
    function changeBallotState(uint8 _new_state) public onlyBallot returns(uint8 flag_) {
        
        uint id = address_to_ballot_id[msg.sender];
        id_to_ballot[id].ballot_state = BallotState(_new_state);
        
        emit BallotStateChanged(msg.sender, id, _new_state, block.timestamp);
        return 1;
    }
    
    function setController(address _new_controller) public onlyController {
        _setController(msg.sender, _new_controller);
    }
    
    
    function getController() external view returns(address controller_) {
        return voting_controller;
    }
    
    function getBallot(uint _ballot_id) external view returns(Ballot memory ballot_){
        ballot_ = id_to_ballot[_ballot_id];
    }
    
    function getVoteWeight(address _voter) external view returns(uint wt_){
        
        require(is_voter[_voter] == 1, "Storage: Not a voter");
        return id_to_voter[address_to_voter_id[_voter]].vote_wt;
        
    }
    
    // Need more details about ballot and status[] also
    function getAllBallots() external view returns(Ballot[] memory ballots_){
        
        Ballot[] memory ballots = new Ballot[](ballot_count);
        
        for(uint i; i<ballot_count; i++){
            ballots[i] = id_to_ballot[i];
        }
        
        return ballots;
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
    
    function _setController(address prev_controller, address new_controller) private {
        require(new_controller != address(0), "Storage: Controller cannot be set to zero address.");
        require(new_controller != address(this), "Storage: This contract is not eligible for controlling itself");
        require(new_controller != prev_controller, "Storage: new controller is same as previous controller");
        voting_controller = new_controller;
        emit ControllerChanged(prev_controller, new_controller, block.timestamp);
    }
    
}