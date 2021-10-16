import { toTokens, EVM_REVERT_MSG } from './helper';

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
      let approveResult;

      beforeEach(async () => {
        await token.approve(exchange.address, toTokens(10), {
          from: accountAddress1,
        });

        approveResult = await exchange.deployerToken(
          token.address,
          toTokens(10),
          { from: accountAddress1 }
        );
      });

      describe('success', () => {
        it('tracks the token deposit', async () => {});
        // Check exchange token balance
      });

      describe('failure', () => {});
    });
  }
);
