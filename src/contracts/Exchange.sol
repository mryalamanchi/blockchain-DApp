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
// [X] Make order
// [X] Cancel order
// [X] Fill order
// [X] Charge fees - earn from every single trade

contract Exchange {
	using SafeMath for uint;

	address public feeAccountAddress; // the account that receives exchange fees
	uint256 public feePercent;
	address constant ETHER_ADDRESS = address(0); // store Ether in tokens mapping with blank address
	mapping(address => mapping(address => uint256)) public tokens;
	mapping(uint256 => _Order) public orders;
	mapping(uint256 =>  bool) public cancelledOrder;
	mapping(uint256 =>  bool) public filledOrder;
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
	event OrderCancelled
	(
		uint256 id,
		address userAddress,
		address tokenGetAddress,
		uint amountGet,
		address tokenGiveAddress,
		uint amountGive,
		uint timestamp
	);
	event Trade(
		uint id,
		address userAddress,
		address addrOfTokenForUserToGet,
		uint amountGet,
		address addrOfTokenGivenByUser,
		uint amountGive,
		address addrOfUserFillingOrder,
		uint timestamp
	);

	// Model the order
	struct _Order
	{
		uint256 id;
		address userAddress;
		address addrOfTokenForUserToGet;
		uint amountGet;
		address addrOfTokenGivenByUser;
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

	function makeOrder(address _addrOfTokenForUserToGet, uint256 _amountGet, address _addrOfTokenGivenByUser, uint256 _amountGive) public
	{
		orderCount = orderCount.add(1);
		orders[orderCount] = _Order(orderCount, msg.sender, _addrOfTokenForUserToGet, _amountGet, _addrOfTokenGivenByUser, _amountGive, now); // now in seconds (epoch)

		emit OrderCreated(orderCount, msg.sender, _addrOfTokenForUserToGet, _amountGet, _addrOfTokenGivenByUser, _amountGive, now);
	}

	function cancelOrder(uint256 _id) public
	{
		_Order storage _order = orders[_id]; // _Order type fetched from "storage" from blockchain
		// Must be "my" order
		require(address(_order.userAddress) == msg.sender);
		// Order must exist (struct will return 0 on properties if it does not exist)
		require(_order.id == _id);

		cancelledOrder[_id] = true;

		emit OrderCancelled(orderCount, msg.sender, _order.addrOfTokenForUserToGet, _order.amountGet, _order.addrOfTokenGivenByUser, _order.amountGive, now);
	}

	function fillOrder(uint256 _id) public
	{
		require(_id > 0 && _id <= orderCount);
		require(!filledOrder[_id]);
		require(!cancelledOrder[_id]);

		_Order storage _order = orders[_id];
		_trade(_order.id, _order.userAddress, _order.addrOfTokenForUserToGet, _order.amountGet, _order.addrOfTokenGivenByUser, _order.amountGive);

		filledOrder[_order.id] = true;
	}

	function _trade(uint256 _orderId, address _userAddress, address _addrOfTokenForUserToGet, uint256 _amountGet, address _addrOfTokenGivenByUser, uint256 _amountGive) internal {
		// Execute trade
		// msg sender is the person filling order
		// _userAddress is the user creates the order

		// Fee paidy by the user filling the order a.k.a. msg.sender
		// Fee deducted from _amountGet

		uint256 _feeAmount = _amountGet.mul(feePercent).div(100);
		// user getting
		// tokens[_addrOfTokenForUserToGet][msg.sender] = tokens[_addrOfTokenForUserToGet][msg.sender].sub(_amountGet.add(_feeAmount)); // order filler need to pay for fee amount as user has paid for them
		tokens[_addrOfTokenForUserToGet][msg.sender] = tokens[_addrOfTokenForUserToGet][msg.sender].sub(_amountGet.add(_feeAmount)); // order filler need to pay for fee amount as user has paid for them
		tokens[_addrOfTokenForUserToGet][_userAddress] = tokens[_addrOfTokenForUserToGet][_userAddress].add(_amountGet);
		
		// Charge fees
		tokens[_addrOfTokenForUserToGet][feeAccountAddress] = tokens[_addrOfTokenForUserToGet][feeAccountAddress].add(_feeAmount);

		// user paying
		tokens[_addrOfTokenGivenByUser][_userAddress] = tokens[_addrOfTokenGivenByUser][_userAddress].sub(_amountGive);
		tokens[_addrOfTokenGivenByUser][msg.sender] = tokens[_addrOfTokenGivenByUser][msg.sender].add(_amountGive);



		// Emit Trade event
		emit Trade(_orderId, _userAddress, _addrOfTokenForUserToGet, _amountGet, _addrOfTokenGivenByUser, _amountGive, msg.sender, now);
	}
}