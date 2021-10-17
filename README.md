# Learn how to build Ethereum token and related Dapp

> The token will follow `ERC-20` Ethereum token standard

- Token - Venus Token
- Dapp

# Technologies

- Develop in `Truffle`
- Develop with fake Ethereum blockchain with `Ganache`
- Build Smart contracts with `Solidity` programming language
- Write Smart contracts tests with assertion library `chai`

`Truffle`: A development environment, testing framework and asset pipeline for blockchains using the Ethereum Virtual Machine (EVM)

## ERC-20 Ethereum token standard

It standardizes the tokens to have certain functions, business logic in the smart contract, including:

- Get name, symbol, decimals (fractional unit)
- Get account's balance
- Get total supply of the cryptocurrency
- Get exchange's allowance
- Transfer
- Approve allowance for exchange
- Delegate transfer to exchange

## Smart Contracts

> Two smart contracts are created in this project and each have different responsibilities.

- Token smart contract
- Exchange smart contract

### Token contract

It conforms the Ethereum `ERC-20` token standard, it encapsulates:

- `what is the token` (name, symbol, decimals etc.)
- highest level policies of `how the token works` (transfer, approve, delegate to exchange actions etc.)

`Token contract` will be used by the `exchange contract`.

### Exchange contract

It is the lower level details contract, it is being used to handle transactions from the user accounts, and it will utilize the `token contract`.

Responsible for `doing transfers for Users` by calling token contract on their behaves:

- `Deposit` token or Ether
- `Withdraw` token or Ether
- `Create` order to actually exchange from Ether to token or vice versa.
- `Filling` order (executing trading) and pay the fee to the feeAccount. (As we charge from users)
- `Cancel` an order created by `myself`
- `Get balance` of `myself` as a user
