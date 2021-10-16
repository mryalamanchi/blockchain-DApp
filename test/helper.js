export const EVM_REVERT_MSG =
  'VM Exception while processing transaction: revert';

export const toTokens = (fractionalTokens) => {
  return new web3.utils.BN(
    web3.utils.toWei(fractionalTokens.toString(), 'ether')
  );
};
