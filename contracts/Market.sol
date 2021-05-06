pragma solidity ^0.6.0;

import './interfaces/ERC1155.sol';
import './interfaces/ERC1155Receiver.sol';

contract Market is ERC1155 , ERC1155TokenReceiver{

    event Open(string name, string symbol, uint256 amount, uint256 tokenId);
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    uint256[] public tokenIds;
    bytes4 private _ERC1155Received;
    bytes4 private _ERC1155BatchReceived;

    mapping(uint256=>bool) private _tokenExists;
    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => string) private _tokenSymbol;
    mapping(uint256 => uint256) private _tokenSupply;
    mapping(address => mapping(address => bool)) private _isApproved;
    mapping(address => mapping(uint256 => uint256)) private _balance;

    constructor() public{

    }



    function _mint(address _emitter, uint256 _tokenId, string memory _name, string memory _symbol,uint256 _amount) internal{
        require(_emitter != address(0), "emitter address is 0");
        require(!_tokenExists[_tokenId], "token already exists");
        tokenIds.push(_tokenId);
        _tokenName[_tokenId] = _name;
        _tokenSymbol[_tokenId] = _symbol;
        _tokenSupply[_tokenId] = _amount;
        _balance[_emitter][_tokenId] = _amount;
        _tokenExists[_tokenId] = true;
        emit Open(_name, _symbol, _amount, _tokenId);
    }

    function onERC1155Received(
        address _operator, 
        address _from, 
        uint256 _id, 
        uint256 _value, 
        bytes calldata _data
    ) external override view returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address _operator, 
        address _from, 
        uint256[] calldata _ids, 
        uint256[] calldata _values, 
        bytes calldata _data
    ) external override view returns(bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }    

    function name(uint256 _tokenId) external view returns(string memory){
        return _tokenName[_tokenId];
    }

    function symbol(uint256 _tokenId) external view returns(string memory){
        return _tokenSymbol[_tokenId];
    }

    function totalSupply(uint256 _tokenId) external view returns(uint256){
        return _tokenSupply[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external override{
        require(_to != address(0));
        require(_balance[_from][_id] >= _value);
        require(_from == msg.sender || _isApproved[_from][msg.sender]);
        require(_checkOnERC1155Received(msg.sender, _from, _to, _id, _value, _data) == true);

        _balance[_from][_id] = _balance[_from][_id] - _value;
        _balance[_to][_id] += _value;

        emit TransferSingle(msg.sender, _from, _to, _id, _value); 
    }

    function safeBatchTransferFrom(
        address _from, 
        address _to, 
        uint256[] calldata _ids, 
        uint256[] calldata _values, 
        bytes calldata _data
    ) external override{
        require(_to != address(0));
        require(_ids.length == _values.length);
        require(_from == msg.sender || _isApproved[_from][msg.sender]);
        require(_checkOnERC1155BatchReceived(msg.sender, _from, _to, _ids, _values, _data) == true);


        for (uint256 i = 0; i < _ids.length; ++i){
            uint256 id = _ids[i];
            uint256 amount = _values[i];

            require(_balance[_from][id] >= amount); 
            _balance[_from][id]= _balance[_from][id] - amount;
            _balance[_to][id] += amount;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
    }

    function balanceOf(
        address _owner, 
        uint256 _id
    ) external override view returns (uint256){
        return _balance[_owner][_id];
    }

    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    ) external override view returns (uint256[] memory){
        require(_owners.length == _ids.length);

        uint256[] memory batch = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i){
            batch[i] = _balance[_owners[i]][_ids[i]];
        }

        return batch;
    }

    function setApprovalForAll(
        address _operator, 
        bool _approved
    ) external override{
        require(msg.sender != _operator);

        _isApproved[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external override view returns (bool){
        return _isApproved[_owner][_operator];
    }

    function _checkOnERC1155Received(
        address _operator, 
        address _from, 
        address _to, 
        uint256 _tokenId, 
        uint256 _amount, 
        bytes memory _data
    ) internal returns (bool){
        if (!isContract(_to)) {
            return true;
        }
        _ERC1155Received = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
        bytes4 retval = ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _tokenId, _amount,_data);
        return (retval == _ERC1155Received);
    }

    function _checkOnERC1155BatchReceived(
        address _operator, 
        address _from, 
        address _to, 
        uint256[] memory _Ids, 
        uint256[] memory _amounts, 
        bytes memory _data
    ) internal returns (bool){
        if (!isContract(_to)) {
            return true;
        }
        _ERC1155BatchReceived = bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
        bytes4 retval = ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _Ids, _amounts,_data);
        return (retval == _ERC1155BatchReceived);
    }

    function isContract(address addr) internal returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

