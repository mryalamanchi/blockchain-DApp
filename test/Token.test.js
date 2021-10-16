import { toTokens, EVM_REVERT_MSG } from './helper';

const Token = artifacts.require('./Token');

require('chai').use(require('chai-as-promised')).should();

contract('Token', ([deployerAddress, receiverAddress, exchangeAddress]) => {
  let token;
  let totalSupply = toTokens(1000000).toString();

  beforeEach(async () => {
    token = await Token.new();
  });

  describe('deployment', () => {
    it('tracks the name', async () => {
      const expectedResult = 'Venus Token';

      const actualResult = await token.name();

      actualResult.should.equal(expectedResult);
    });

    it('tracks the symbol', async () => {
      const expectedResult = 'VEN';

      const actualResult = await token.symbol();

      actualResult.should.equal(expectedResult);
    });

    it('tracks the decimals', async () => {
      const expectedResult = 18;

      const actualResult = await token.decimals();

      actualResult.toString().should.equal(expectedResult.toString());
    });

    it('tracks the total supply', async () => {
      const expectedResult = totalSupply.toString();

      const actualResult = await token.totalSupply();

      actualResult.toString().should.equal(expectedResult);
    });

    it('assings the total supply to the deployer', async () => {
      const expectedResult = totalSupply.toString();

      const actualResult = await token.balanceOf(deployerAddress);

      actualResult.toString().should.equal(expectedResult);
    });
  });

  describe('sending tokens', () => {
    let transferAmount;
    let transferResult;

    describe('success', async () => {
      beforeEach(async () => {
        transferAmount = toTokens(100);
        transferResult = await token.transfer(receiverAddress, transferAmount, {
          from: deployerAddress,
        });
      });

      it('transfers token balances', async () => {
        // Balance after transfer
        const newDeployerBalance = await token.balanceOf(deployerAddress);
        newDeployerBalance.toString().should.equal(toTokens(999900).toString());

        const newReceiverBalance = await token.balanceOf(receiverAddress);
        newReceiverBalance.toString().should.equal(toTokens(100).toString());
      });

      it('emits a transfer event', async () => {
        const log = transferResult.logs[0];

        log.event.should.eq('Transfer');

        const transferEvent = log.args;
        transferEvent.from
          .toString()
          .should.equal(
            deployerAddress,
            'transferred from the expected deployer'
          );
        transferEvent.to.should.equal(
          receiverAddress,
          'transferred to the expected receiver'
        );
        transferEvent.value
          .toString()
          .should.equal(transferAmount.toString(), 'transfer value is correct');
      });
    });

    describe('failure', async () => {
      it('rejects insufficient balances', async () => {
        let invalidAmount;
        invalidAmount = toTokens(100000000); // 100 million - greater than total supply

        await token
          .transfer(receiverAddress, invalidAmount, {
            from: deployerAddress,
          })
          .should.be.rejectedWith(EVM_REVERT_MSG);
      });

      it('rejects invalid recipients', async () => {
        const invalidAddress = 0x0;

        await token.transfer(invalidAddress, transferAmount, {
          from: deployerAddress,
        }).should.be.rejected;
      });
    });

    describe('approving tokens allowance to exchange (delegate transfer to others)', () => {
      let approvalResult;
      let approvalAmount;

      beforeEach(async () => {
        approvalAmount = toTokens(100);
        approvalResult = await token.approve(exchangeAddress, approvalAmount, {
          from: deployerAddress,
        });
      });

      describe('success', () => {
        it('allocates an allowance for delegated token spending on exchange', async () => {
          const allowance = await token.allowance(
            deployerAddress,
            exchangeAddress
          );

          allowance.toString().should.equal(approvalAmount.toString());
        });

        it('emits an Approval event', async () => {
          const log = approvalResult.logs[0];
          log.event.should.eq('Approval');

          const approvalEvent = log.args;
          approvalEvent.owner
            .toString()
            .should.equal(deployerAddress, 'owner is correct');
          approvalEvent.spender.should.equal(
            exchangeAddress,
            'spender is correct'
          );
          approvalEvent.value
            .toString()
            .should.equal(approvalAmount.toString(), 'value is correct');
        });
      });

      describe('failure', () => {
        it('rejects invalid delegated spenders', async () => {
          await token.approve(0x0, approvalAmount, { from: deployerAddress })
            .should.be.rejected;
        });
      });
    });

    describe('delegated token transfers (to exchange etc.)', () => {
      let transferResult;
      let transferAmount;

      beforeEach(async () => {
        transferAmount = toTokens(100);

        // approve allowance to the exchange
        await token.approve(exchangeAddress, transferAmount, {
          from: deployerAddress,
        });
      });

      describe('success', () => {
        beforeEach(async () => {
          // exchange can now transfer on behave of sender
          transferResult = await token.transferFrom(
            deployerAddress,
            receiverAddress,
            transferAmount,
            {
              from: exchangeAddress,
            }
          );
        });

        it('transfers token balances', async () => {
          // Balance after transfer
          const newDeployerBalance = await token.balanceOf(deployerAddress);
          newDeployerBalance
            .toString()
            .should.equal(toTokens(999900).toString());

          const newReceiverBalance = await token.balanceOf(receiverAddress);
          newReceiverBalance.toString().should.equal(toTokens(100).toString());
        });

        it('reset the allowance', async () => {
          const allowance = await token.allowance(
            deployerAddress,
            exchangeAddress
          );

          allowance.toString().should.equal('0');
        });

        it('emits a transfer event', async () => {
          const log = transferResult.logs[0];

          log.event.should.eq('Transfer');

          const transferEvent = log.args;
          transferEvent.from
            .toString()
            .should.equal(
              deployerAddress,
              'transferred from the expected sender'
            );
          transferEvent.to.should.equal(
            receiverAddress,
            'transferred to the expected receiver'
          );
          transferEvent.value
            .toString()
            .should.equal(
              transferAmount.toString(),
              'transfer value is correct'
            );
        });
      });

      describe('failure', () => {
        it('rejects invalid recipients', async () => {
          await token.transferFrom(deployerAddress, 0x0, transferAmount, {
            from: exchangeAddress,
          }).should.be.rejected;
        });

        it('rejects insufficient balances', async () => {
          let invalidAmount;
          invalidAmount = toTokens(100000000); // 100 million - greater than sender's balance

          await token
            .transferFrom(deployerAddress, receiverAddress, invalidAmount, {
              from: exchangeAddress,
            })
            .should.be.rejectedWith(EVM_REVERT_MSG);
        });

        it('rejects insufficient allowance for the exchange', async () => {
          let invalidAmount;
          invalidAmount = toTokens(100000000); // 100 million - greater than allowance of exchange

          await token
            .transferFrom(deployerAddress, receiverAddress, invalidAmount, {
              from: exchangeAddress,
            })
            .should.be.rejectedWith(EVM_REVERT_MSG);
        });
      });
    });
  });
});
