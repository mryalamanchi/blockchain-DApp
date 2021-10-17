pragma solidity ^0.5.0;

import "./Token.sol";

// Deposit & Withdraw Funds
// Manage Orders - Make or Cancel
// Handle Trades - Charge fees

// TODO:
// [X] Set the fee (for when deploying smart contract etc.)
// [X] Deposit Ether
// [X] Withdraw Ether
// [X] Deposit tokens
// [X] Withdraw tokens
// [X] Check balances
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
	mapping(uint256 => _Order) public orders;
	uint256 public orderCount;

	// Events
	event Deposit(address tokenAddress, address userAddress, uint256 amount, uint256 userBalanceInExchange);
	event Withdraw(address tokenAddress, address userAddress, uint256 amount, uint256 userBalanceInExchange);
	event OrderCreated(
		uint256 id,
		address userAddress,
		address tokenGetAddress,
		uint amountGet,
		address tokenGiveAddress,
		uint amountGive,
		uint timestamp
	);

	// Model the order
	struct _Order
	{
		uint256 id;
		address userAddress;
		address tokenGetAddress;
		uint amountGet;
		address tokenGiveAddress;
		uint amountGive;
		uint timestamp;
	}

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

	function withdrawToken(address _tokenAddress, uint _amount) public
	{
		// reject if is ether address
		require(_tokenAddress != ETHER_ADDRESS);

		uint256 userBalanceBeforeWithdrawl = tokens[_tokenAddress][msg.sender];
		// reject if withdraw invalid amount (not sufficient)
		require(userBalanceBeforeWithdrawl >= _amount);
		// reduce amount recorded in exchange contract
		tokens[_tokenAddress][msg.sender] = userBalanceBeforeWithdrawl.sub(_amount);

		// reduce amount recorded in token contract and transfer back to user
		require(Token(_tokenAddress).transfer(msg.sender, _amount));

		// emit event
		uint256 userBalanceAfterWithdrawl = tokens[_tokenAddress][msg.sender];
		emit Withdraw(_tokenAddress, msg.sender, _amount, userBalanceAfterWithdrawl);
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

	function withdrawEther(uint _amount) public
	{
		uint256 userBalanceBeforeWithrawal = tokens[ETHER_ADDRESS][msg.sender];
		require(userBalanceBeforeWithrawal >= _amount);
		tokens[ETHER_ADDRESS][msg.sender] = userBalanceBeforeWithrawal.sub(_amount);

		// transfer back to the withdrawer
		msg.sender.transfer(_amount);

		uint256 userBalanceAfterWithdrawl = tokens[ETHER_ADDRESS][msg.sender];
		emit Withdraw(ETHER_ADDRESS, msg.sender, _amount, userBalanceAfterWithdrawl);
	}

	function balanceOf(address _tokenOrEtherAddress, address _userAddress) public view returns (uint256)
	{
		return tokens[_tokenOrEtherAddress][_userAddress];
	}

	function makeOrder(address _tokenGetAddress, uint256 _amountGet, address _tokenGiveAddress, uint256 _amountGive) public
	{
		orderCount = orderCount.add(1);
		orders[orderCount] = _Order(orderCount, msg.sender, _tokenGetAddress, _amountGet, _tokenGiveAddress, _amountGive, now); // now in seconds (epoch)

		emit OrderCreated(orderCount, msg.sender, _tokenGetAddress, _amountGet, _tokenGiveAddress, _amountGive, now);
	}
}