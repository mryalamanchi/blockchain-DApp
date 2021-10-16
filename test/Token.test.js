import { toTokens, EVM_REVERT_MSG } from './helper';

const Token = artifacts.require('./Token');

require('chai').use(require('chai-as-promised')).should();

contract('Token', ([deployerAddress, receiverAddress]) => {
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
  });
});
