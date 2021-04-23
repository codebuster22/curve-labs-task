// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ISafeController {
    
    function initialiseSafeController(address _safe, address _controller) external;
    function setController(address _new_controller) external;
    function setSafeManager(address _new_safe_manager) external ;
    function createOwnershipProposal(uint8 _action, address _proposedOwner, uint _newThreshold) external;
    function yes(uint _proposal_id, uint _yesWt, address _voter) external;
    function no(uint _proposal_id, uint _noWt, address _voter) external; 
    
    function getController() external view returns(address controller_);
    function getSafeManager() external view returns(address safe_manager_);
    
}