pragma solidity ^0.5.0;

import "./Token.sol";

// Deposit & Withdraw Funds
// Manage Orders - Make or Cancel
// Handle Trades - Charge fees

// TODO:
// [X] Set the fee (for when deploying smart contract etc.)
// [X] Deposit Ether
// [ ] Withdraw Ether
// [X] Deposit tokens
// [ ] Withdraw tokens
// [ ] Check balances
// [ ] Make order
// [ ] Cancel order
// [ ] Fill order
// [ ] Charge fees - earn from every single trade

contract Exchange {
	using SafeMath for uint;

	address public feeAccountAddress; // the account that receives exchange fees
	uint256 public feePercent;
	address constant ETHER_ADDRESS = address(0); // store Ether in tokens mapping with blank address
	mapping(address => mapping(address => uint256)) public tokens;

	// Events
	event Deposit(address tokenAddress, address userAddress, uint256 amount, uint256 userBalanceInExchange);

	constructor(address _feeAccountAddress, uint256 _feePercent) public {
		feeAccountAddress = _feeAccountAddress;
		feePercent = _feePercent;
	}

	// NOTE: We only handle VEN tokens, if someone send Ether (not just deposit), we need a fallback to refund to them
	function() external {
		revert();
	}

	function depositToken(address _tokenAddress, uint _amount) public
	{
		// Don't allow Ether deposits since this function is for depositing VEN token
		require(_tokenAddress != ETHER_ADDRESS);

		// 1. deposit token = transfer token from user to exchange
		require(Token(_tokenAddress).transferFrom(msg.sender, address(this), _amount)); // address(this) = this smart contract

		// 2. register the user balance on that token
		uint256 userBalanceInExchangeBeforeDeposite = tokens[_tokenAddress][msg.sender];
		tokens[_tokenAddress][msg.sender] = userBalanceInExchangeBeforeDeposite.add(_amount); // default to 0

		uint256 userBalanceInExchangeAfterDeposite = tokens[_tokenAddress][msg.sender];
		emit Deposit(_tokenAddress, msg.sender, _amount, userBalanceInExchangeAfterDeposite);
	}


	function depositEther() payable public
	{
		// TODO: Don't allow tokens to be deposited with this function, only for Ether

		// msg.value = amount of Ether get sent in the function with payable (global variable)
		uint256 userBalanceInExchangeBeforeDeposite = tokens[ETHER_ADDRESS][msg.sender];
		tokens[ETHER_ADDRESS][msg.sender] = userBalanceInExchangeBeforeDeposite.add(msg.value); // default to 0

		uint256 userBalanceInExchangeAfterDeposite = tokens[ETHER_ADDRESS][msg.sender];
		emit Deposit(ETHER_ADDRESS, msg.sender, msg.value, userBalanceInExchangeAfterDeposite);
	}
}