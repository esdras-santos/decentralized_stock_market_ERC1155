pragma solidity ^0.6.0;

import './interfaces/IERC1155.sol';
import './interfaces/IERC1155TokenReceiver.sol';


contract ERC1155 is IERC1155, IERC1155TokenReceiver{
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    mapping (address => mapping(uint256 => uint256)) private _balance;
    mapping (address => uint256) private _etherBalance;
    mapping (address => mapping (address => bool)) private _approv;

    bytes4 private _ERC1155Received = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    bytes4 private _ERC1155BatchReceived = bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));

    constructor() public {        
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

    //test function
    function mint(uint256 id, uint256 amount) external {
        
        _balance[msg.sender][id] = amount;
    }

    //if ether are sended to the contract
    fallback() external payable{
        require(msg.data.length == 0);
        _etherBalance[msg.sender] += msg.value;
    }

    function depositEther() external payable{
        _etherBalance[msg.sender] += msg.value;
    }
    
    function etherBalanceOf(address owner) external view returns(uint256){
        return _etherBalance[owner];
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external override{
        require(_to != address(0) && _from != address(0));
        require(_balance[_from][_id] >= _value);
        require(_approv[_from][msg.sender] || _from == msg.sender);
        _balance[_from][_id] = _balance[_from][_id] - _value;
        _balance[_to][_id] += _value; 
        emit TransferSingle(msg.sender, _from,  _to, _id, _value);
        require(_checkOnERC1155Received(msg.sender, _from, _to, _id, _value, _data));
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override{
        require(_to != address(0) && _from != address(0));
        require(_ids.length != _values.length);
        require(_approv[_from][msg.sender] || _from == msg.sender);
        for (uint256 i = 0; i < _ids.length; ++i) {
            require(_balance[_from][_ids[i]] >= _values[i]);
            _balance[_from][_ids[i]] -= _values[i];
            _balance[_to][_ids[i]] += _values[i];
        }
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        require(_checkOnERC1155BatchReceived(msg.sender, _from, _to, _ids, _values, _data));
    }

    function balanceOf(address _owner, uint256 _id) external override view returns (uint256){
        require(_owner != address(0));
        return _balance[_owner][_id];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external override view returns (uint256[] memory){
        uint256[] memory _balances;
        for (uint256 i = 0; i < _owners.length; ++i) {
            require(_owners[i] != address(0));
            _balances[i] = _balance[_owners[i]][_ids[i]]; 
        }
        return _balances;
    }

    function setApprovalForAll(address _operator, bool _approved) external override{
        require(_operator != address(0));
        require(msg.sender != _operator);

        _approv[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool){
        return _approv[_owner][_operator];
    }

    function _checkOnERC1155Received(
        address _operator, 
        address _from, 
        address _to, 
        uint256 _tokenId, 
        uint256 _amount, 
        bytes memory _data
    ) internal view returns (bool){
        if (!isContract(_to)) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _tokenId, _amount,_data);
        return (retval == _ERC1155Received);
    }

    function _checkOnERC1155BatchReceived(
        address _operator, 
        address _from, 
        address _to, 
        uint256[] memory _Ids, 
        uint256[] memory _amounts, 
        bytes memory _data
    ) internal view returns (bool){
        if (!isContract(_to)) {
            return true;
        }
        
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _Ids, _amounts,_data);
        return (retval == _ERC1155BatchReceived);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly{ size := extcodesize(addr)}
        return size > 0;
    }
}