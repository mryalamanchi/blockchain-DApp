pragma solidity ^0.5.9;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Token {
	// ERC20 Token standard for Ethereum token
	using SafeMath for uint;

	string public name = "Venus Token";
	string public symbol = "VEN";
	// fractional unit
	uint256 public decimals = 18;
	uint256 public totalSupply;

	mapping(address => uint256) public balanceOf;
	/*
		The ERC-20 standard allow an address to give an allowance to another address to be able to retrieve tokens from it. This getter returns the remaining number of tokens that the spender will be allowed to spend on behalf of owner. 
	*/
	mapping(address => mapping(address => uint256)) public allowance;

	// Events
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	constructor() public {
		totalSupply = 1000000 * (10 ** decimals);
		// msg.sender return the address that deploy this smart contract
		balanceOf[msg.sender] = totalSupply;
	}

		function _transfer(address _from, address _to, uint256 _value) internal
	{
		require(_to != address(0));
		require(balanceOf[_from] >= _value);

		balanceOf[_from] = balanceOf[_from].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);

		// send transfer event
		emit Transfer(_from, _to, _value);
	}

	function transfer(address _to, uint256 _value) public returns (bool isSuccess)
	{

		_transfer(msg.sender, _to, _value);

		return true;
	}


	// Approve tokens
	function approve(address _spender, uint256 _value) public returns (bool isSuccess)
	{
		require(_spender != address(0));
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	// Transfer from 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool isSuccess)
	{
		// _from represent the actual user WANTS to send the transfer
		// msg.sender is the initiator of the transferFrom, which is the exchange

		// exchange (entity that being delegated) must have enough allowance to perform transfer
		require(allowance[_from][msg.sender] >= _value);

		_transfer(_from, _to, _value);
		 allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

		return true;
	}
}