import { tokens, ether, EVM_REVERT_MSG, ETHER_ADDRESS } from './helper';

const Token = artifacts.require('./Token');
const Exchange = artifacts.require('./Exchange');

require('chai').use(require('chai-as-promised')).should();

contract.only(
  'Exchange',
  ([deployerAddress, feeAccountAddress, accountAddress1]) => {
    let token;
    let exchange;
    const feePercent = 10;

    beforeEach(async () => {
      token = await Token.new();

      // !!Need to give test user account some tokens before starting test!!
      token.transfer(accountAddress1, tokens(100), { from: deployerAddress });

      // Deploy exchange
      exchange = await Exchange.new(feeAccountAddress, feePercent);
    });

    describe('deployment', () => {
      it('tracks the fee account', async () => {
        const actualResult = await exchange.feeAccountAddress();

        actualResult.should.equal(feeAccountAddress);
      });

      it('tracks the fee percentage', async () => {
        const actualResult = await exchange.feePercent();

        actualResult.toString().should.equal(feePercent.toString());
      });
    });

    describe('depositing tokens', () => {
      let approveAmount;
      let transferAmount;
      let depositTokenResult;

      describe('success', () => {
        beforeEach(async () => {
          approveAmount = tokens(10);
          transferAmount = tokens(10);

          await token.approve(exchange.address, approveAmount, {
            from: accountAddress1,
          });

          depositTokenResult = await exchange.depositToken(
            token.address,
            transferAmount,
            { from: accountAddress1 }
          );
        });

        it('tracks the token deposit', async () => {
          // Check exchange token balance after user deposit tokens to exchange
          const exchangeBalance = await token.balanceOf(exchange.address);
          exchangeBalance.toString().should.equal(transferAmount.toString());

          // Check user's tokens on exchange
          const userAccountBalance = await exchange.tokens(
            token.address,
            accountAddress1
          );
          userAccountBalance.toString().should.equal(transferAmount.toString());
        });

        it('emits a deposit event', async () => {
          const log = depositTokenResult.logs[0];
          log.event.should.eq('Deposit');

          const depositTokenEvent = log.args;

          depositTokenEvent.tokenAddress.should.equal(
            token.address,
            'token address is correct'
          );
          depositTokenEvent.userAddress.should.equal(
            accountAddress1,
            'user address is correct'
          );
          depositTokenEvent.amount
            .toString()
            .should.equal(transferAmount.toString(), 'amount is correct');
          depositTokenEvent.userBalanceInExchange
            .toString()
            .should.equal(
              transferAmount.toString(),
              'user balance in exchange is correct'
            );
        });
      });

      describe('failure', () => {
        it('rejects Ether deposits', async () => {
          await exchange
            .depositToken(
              ETHER_ADDRESS, // empty address, 0 x 40
              transferAmount,
              {
                from: accountAddress1,
              }
            )
            .should.be.rejectedWith(EVM_REVERT_MSG);
        });

        it('fails when no tokens are approved', async () => {
          // We didn't not approve any tokens allowance before depositing, and it should fail
          await exchange
            .depositToken(token.address, transferAmount, {
              from: accountAddress1,
            })
            .should.be.rejectedWith(EVM_REVERT_MSG);
        });
      });
    });

    describe('withdrawing tokens', () => {
      let withdrawAmount;
      let withdrawTokenResult;

      describe('success', () => {
        beforeEach(async () => {
          const userBalanceBeforeWithdrawal = tokens(1);
          // Deposit tokens first from exchange
          await token.approve(exchange.address, userBalanceBeforeWithdrawal, {
            from: accountAddress1,
          });
          // Exchange deposit VEN Token for user
          await exchange.depositToken(
            token.address,
            userBalanceBeforeWithdrawal,
            {
              from: accountAddress1,
            }
          );

          withdrawAmount = tokens(1);

          withdrawTokenResult = await exchange.withdrawToken(
            token.address,
            withdrawAmount,
            {
              from: accountAddress1,
            }
          );
        });

        it('user token balance should be 0 after withdrawing tokens', async () => {
          const userBalanceAfterWithdrawal = await exchange.tokens(
            token.address,
            accountAddress1
          );
          userBalanceAfterWithdrawal.toString().should.equal('0');
        });

        it('emits a deposit event for tokens', async () => {
          const log = withdrawTokenResult.logs[0];
          log.event.should.eq('Withdraw');

          const withdrawEtherEvent = log.args;

          withdrawEtherEvent.tokenAddress.should.equal(
            token.address,
            'token address is correct'
          );
          withdrawEtherEvent.userAddress.should.equal(
            accountAddress1,
            'user address is correct'
          );
          withdrawEtherEvent.amount
            .toString()
            .should.equal(withdrawAmount.toString(), 'amount is correct');
          withdrawEtherEvent.userBalanceInExchange
            .toString()
            .should.equal('0', 'user balance in exchange is correct');
        });
      });

      describe('failure', () => {
        it('reject Ether withdraws', async () => {
          await exchange
            .withdrawToken(ETHER_ADDRESS, withdrawAmount, {
              from: accountAddress1,
            })
            .should.be.rejectedWith(EVM_REVERT_MSG);
        });

        it('fails for insufficient balances', async () => {
          // Attempt the withdraw without depositing any for user
          await exchange
            .withdrawToken(token.address, withdrawAmount, {
              from: accountAddress1,
            })
            .should.be.rejectedWith(EVM_REVERT_MSG);
        });
      });
    });

    describe('depositing ether', () => {
      let transferAmount;
      let depositEtherResult;

      describe('success', () => {
        beforeEach(async () => {
          // no need approve allowance as our coin is VEN not Ether
          transferAmount = ether(1);

          depositEtherResult = await exchange.depositEther({
            from: accountAddress1,
            value: transferAmount,
          });
        });

        it('tracks the Ether deposit', async () => {
          // Check user's tokens on exchange
          const userAccountBalance = await exchange.tokens(
            ETHER_ADDRESS,
            accountAddress1
          );
          userAccountBalance.toString().should.equal(transferAmount.toString());
        });

        it('emits a deposit event', async () => {
          const log = depositEtherResult.logs[0];
          log.event.should.eq('Deposit');

          const depositTokenEvent = log.args;

          depositTokenEvent.tokenAddress.should.equal(
            ETHER_ADDRESS,
            'ether address is correct'
          );
          depositTokenEvent.userAddress.should.equal(
            accountAddress1,
            'user address is correct'
          );
          depositTokenEvent.amount
            .toString()
            .should.equal(transferAmount.toString(), 'amount is correct');
          depositTokenEvent.userBalanceInExchange
            .toString()
            .should.equal(
              transferAmount.toString(),
              'user balance in exchange is correct'
            );
        });
      });
    });

    describe('withdrawing ether', () => {
      let withdrawAmount;
      let withdrawEtherResult;

      beforeEach(async () => {
        // no need approve allowance as our coin is VEN not Ether
        const userBalanceBeforeWithdrawal = ether(1);

        await exchange.depositEther({
          from: accountAddress1,
          value: userBalanceBeforeWithdrawal,
        });
      });

      describe('success', () => {
        beforeEach(async () => {
          // no need approve allowance as our coin is VEN not Ether
          withdrawAmount = ether(1);

          withdrawEtherResult = await exchange.withdrawEther(withdrawAmount, {
            from: accountAddress1,
          });
        });

        it('user Ether balance should be 0 after withdrawing Ether funds', async () => {
          const userBalanceAfterWithdrawal = await exchange.tokens(
            ETHER_ADDRESS,
            accountAddress1
          );
          userBalanceAfterWithdrawal.toString().should.equal('0');
        });

        it('emits a deposit event for Ether', async () => {
          const log = withdrawEtherResult.logs[0];
          log.event.should.eq('Withdraw');

          const withdrawEtherEvent = log.args;

          withdrawEtherEvent.tokenAddress.should.equal(
            ETHER_ADDRESS,
            'ether address is correct'
          );
          withdrawEtherEvent.userAddress.should.equal(
            accountAddress1,
            'user address is correct'
          );
          withdrawEtherEvent.amount
            .toString()
            .should.equal(withdrawAmount.toString(), 'amount is correct');
          withdrawEtherEvent.userBalanceInExchange
            .toString()
            .should.equal('0', 'user balance in exchange is correct');
        });
      });

      describe('success', () => {
        it('rejects withdraws for insufficient balances', async () => {
          const withdrawAmountUserCantAfford = ether(2000);
          await exchange
            .withdrawEther(withdrawAmountUserCantAfford, {
              from: accountAddress1,
            })
            .should.be.rejectedWith(EVM_REVERT_MSG);
        });
      });
    });

    describe('fallback', () => {
      it('reverts (refunds) when Ether is sent', async () => {
        await exchange
          .sendTransaction({
            from: accountAddress1,
            value: ether(1),
          })
          .should.be.rejectedWith(EVM_REVERT_MSG);
      });
    });

    describe.only('checking balances', async () => {
      let depositAmount;

      beforeEach(async () => {
        depositAmount = ether(1);
        exchange.depositEther({ from: accountAddress1, value: depositAmount });
      });

      it('returns user balance', async () => {
        const userBalance = await exchange.balanceOf(
          ETHER_ADDRESS,
          accountAddress1
        );

        userBalance.toString().should.equal(depositAmount.toString());
      });
    });
  }
);
