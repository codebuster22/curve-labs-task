// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/Context.sol";

contract Stoppable is Context{
    
    enum State{STOPPED, STARTED}
    
    State private state;
    
    event Stopped(address account, uint timestamp);
    event Started(address account, uint timestamp);
    
    modifier whenStopped() {
        require( state == State.STOPPED, "Stoppable: Started");
        _;
    }
    
    modifier whenNotStopped() {
        require( state == State.STARTED, "Stoppable: Stopped");
        _;
    }
    
    function _stop() internal whenNotStopped {
        state = State.STOPPED;
        emit Stopped(_msgSender(), block.timestamp);
    }
    
    function _start() internal whenStopped {
        state = State.STARTED;
        emit Started(_msgSender(), block.timestamp);
    }
    
    
    // Read only Functions
    
    function stopped() public view virtual returns (uint8 is_stopped){
        is_stopped = uint8(state);
    }
    
}