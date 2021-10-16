pragma solidity ^0.5.0;

import "./Token.sol";

// Deposit & Withdraw Funds
// Manage Orders - Make or Cancel
// Handle Trades - Charge fees

// TODO:
// [X] Set the fee (for when deploying smart contract etc.)
// [ ] Deposit Ether
// [ ] Withdraw Ether
// [ ] Deposit tokens
// [ ] Withdraw tokens
// [ ] Check balances
// [ ] Make order
// [ ] Cancel order
// [ ] Fill order
// [ ] Charge fees - earn from every single trade

contract Exchange {
	address public feeAccountAddress; // the account that receives exchange fees
	uint256 public feePercent;

	constructor(address _feeAccountAddress, uint256 _feePercent) public {
		feeAccountAddress = _feeAccountAddress;
		feePercent = _feePercent;
	}

	function depositToken(address _tokenAddress, uint _amount) public
	{
		Token(_tokenAddress).transferFrom(msg.sender, address(this), _amount); // address(this) = this smart contract
		// Which token?
		// How much?
		// Send tokens to this contract
		// Manage deposit - update balance
		// Emit event
	}
}