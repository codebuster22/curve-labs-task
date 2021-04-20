// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/Context.sol";

contract Administrable is Context {
    
    mapping(address => uint8) private _is_admin;
    uint private _admin_count;
    
    event NewAdminAdded(address indexed new_admin, address indexed requester, uint timestamp);
    event AdminResigned(address indexed prev_admin, uint timestamp);
    
    constructor () {
        _addAdmin(_msgSender());
        emit NewAdminAdded(_msgSender(), address(0), block.timestamp);
    }
    
    modifier onlyAdmin() {
        require(_is_admin[_msgSender()] == 1, "Administrable: You are not the Admin");
        _;
    }
    
    function addAdmin(address _new_admin) public onlyAdmin {
        require(_new_admin != address(0), "Administrable: New Admin's address is zero");
        emit NewAdminAdded(_new_admin, _msgSender(), block.timestamp);
        _addAdmin(_new_admin);
    }
    
    function resignAsAdmin() public onlyAdmin{
        require(_admin_count > 1, "Administrable: Cannot govern without any admin");
        emit AdminResigned(_msgSender(), block.timestamp);
        _resignAsAdmin(msg.sender);
    }
    
    
    // Low level function
    
    function _addAdmin(address new_admin) private{
        _is_admin[new_admin] = 1;
        _admin_count++;
    }
    
    function _resignAsAdmin(address _admin) private{
        _is_admin[_admin] = 0;
        _admin_count--;
    }
    
    
    // Read only functions
    
    function checkIsAdmin(address _param) external view returns(uint8 flag){
        flag = _is_admin[_param];
    }
    
}