export const ETHER_ADDRESS = '0x0000000000000000000000000000000000000000';

export const EVM_REVERT_MSG =
  'VM Exception while processing transaction: revert';

export const tokens = (fractionalTokens) => {
  return new web3.utils.BN(
    web3.utils.toWei(fractionalTokens.toString(), 'ether')
  );
};

export const ether = (wei) => {
  return new web3.utils.BN(web3.utils.toWei(wei.toString(), 'ether'));
};
