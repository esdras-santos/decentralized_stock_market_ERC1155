pragma solidity ^0.6.0;

import './interfaces/ERC1155.sol';

contract Market is ERC1155{

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    mapping(address => mapping(address => bool)) private _isApproved;
    mapping(address => mapping(uint256 => uint256)) private _balance;

    constructor() public{

    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external{
        require(_to != address(0));
        require(this.balanceOf(_from, _id) >= _value);
        require(_from == msg.sender || this.isApprovedForAll(_from, msg.sender));
        
        _balance[_from][_id] = this.balanceOf(_from, _id) - _value;
        _balance[_to][_id] += _value;

        emit TransferSingle(msg.sender, _from, _to, _id, _value); 
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external{

    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256){
        return _balance[_owner][_id];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return _isApproved[_owner][_operator];
    }

}