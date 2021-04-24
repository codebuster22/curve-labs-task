// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStorage{
    function registerVoter(address _voter, string memory _name)             external returns(uint8 flag_);
    function createBallot(address _ballot_address, string memory _title)    external returns(uint8 flag_);
    function changeBallotState(uint8 _new_state)                            external returns(uint8 flag_);
    function cancelBallot(uint _ballot_id)                                  external returns(uint8 flag_);
    function setController(address _new_controller)                         external;
    
    function is_voter(address _voter)          external view returns(uint8);
    function getVoteWeight(address _voter)     external view returns(uint wt_);
    function getBallotAddress(uint _ballot_id) external view returns(address ballot_address_);
}