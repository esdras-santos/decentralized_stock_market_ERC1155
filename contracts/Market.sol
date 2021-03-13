pragma solidity ^0.6.0;

import './interfaces/ERC1155.sol';

contract Market is ERC1155{

    mapping(address => mapping(uint256 => uint256)) private _balance;

    constructor() public{

    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external{
        require(_to != address(0));
        require(this.balanceOf(_from, _id) <= _value);
        
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256){
        return _balance[_owner][_id];
    }

}