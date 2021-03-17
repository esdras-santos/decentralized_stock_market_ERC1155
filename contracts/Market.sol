pragma solidity ^0.6.0;

import './interfaces/ERC1155.sol';
import './interfaces/ERC1155Receiver.sol';

contract Market is ERC1155, ERC1155TokenReceiver{

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    mapping(address => mapping(address => bool)) private _isApproved;
    mapping(address => mapping(uint256 => uint256)) private _balance;

    constructor() public{

    }

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }    

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external{
        require(_to != address(0));
        require(this.balanceOf(_from, _id) >= _value);
        require(_from == msg.sender || this.isApprovedForAll(_from, msg.sender));
        require(_checkOnERC1155Received(msg.sender, _from, _to, _id, _value, _data) == true);

        _balance[_from][_id] = this.balanceOf(_from, _id) - _value;
        _balance[_to][_id] += _value;

        emit TransferSingle(msg.sender, _from, _to, _id, _value); 
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external{
        require(_to != address(0));
        require(_ids.length == _values.length);
        require(_from == msg.sender || this.isApprovedForAll(_from, msg.sender));
        require(_checkOnERC1155BatchReceived(msg.sender, _from, _to, _id, _value, _data) == true);


        for (uint256 i = 0; i < _ids.length; ++i){
            uint256 id = ids[i];
            uint256 amount = _values[i];

            require(balanceOf(_from,id) >= amount);
            _balance[_from][id] = balanceOf(_from,id) - amount;
            _balance[_to][id] += amount;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256){
        return _balance[_owner][_id];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory){
        require(_owners.length == _ids.length);

        uint256[] memory batch = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i){
            batch[i] = balanceOf(_owners[i], _ids[i]);
        }

        return batch;
    }

    function setApprovalForAll(address _operator, bool _approved) external{
        require(msg.sender != _operator);

        _isApproved[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return _isApproved[_owner][_operator];
    }

    function _checkOnERC1155Received(address _operator, address _from, address _to, uint256 _tokenId, uint256 _amount, bytes memory _data) internal returns (bool){
        if (!_to.isContract()) {
            return true;
        }

        bytes4 retval = ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _tokenId, _amount,_data);
        return (retval == _ERC721Received);
    }

    function _checkOnERC1155BatchReceived(address _operator, address _from, address _to, uint256[] memory _Ids, uint256[] memory _amounts, bytes memory _data) internal returns (bool){
        if (!_to.isContract()) {
            return true;
        }

        bytes4 retval = ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _Ids, _amounts,_data);
        return (retval == _ERC721Received);
    }

}