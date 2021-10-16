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

	// Events
	event Transfer(address indexed from, address indexed to, uint256 value);

	constructor() public {
		totalSupply = 1000000 * (10 ** decimals);
		// msg.sender return the address that deploy this smart contract
		balanceOf[msg.sender] = totalSupply;
	}

	function transfer(address _to, uint256 _value) public returns (bool isSuccess)
	{
		// throw exception
		require(_to != address(0));
		require(balanceOf[msg.sender] >= _value);

		// check if sender has enough balance

		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);

		// send transfer event
		emit Transfer(msg.sender, _to, _value);

		return true;
	}
}