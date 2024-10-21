import { describe, it, expect } from 'vitest';
import { Clarinet, Tx, Chain, Account, types } from 'clarinet';

describe('Crowdsourced Digital Monument contract', () => {
  it('should allow submitting a new proposal', async () => {
    await Clarinet.run(async (chain: Chain) => {
      const deployer = chain.wallet('deployer');
      const user1 = chain.wallet('user1');
      
      // Submit a new proposal
      const proposeResult = await chain.callContract(
          'crowdsourced-monument',
          'submit-proposal',
          [types.buff(32, '0123456789abcdef0123456789abcdef')],
          { sender: user1.address }
      );
      
      expect(proposeResult.result).toEqual(
          `(ok u1)`,
          'Proposal submission should succeed'
      );
      
      // Check the proposal details
      const proposal = await chain.getMap('proposals', 'u1');
      expect(proposal).toEqual({
        contributor: user1.address,
        'content-hash': '0123456789abcdef0123456789abcdef',
        'voting-start': '0',
        'yes-votes': '0',
        'no-votes': '0',
        processed: false,
      });
    });
  });
  
  it('should allow voting on a proposal', async () => {
    await Clarinet.run(async (chain: Chain) => {
      const deployer = chain.wallet('deployer');
      const user1 = chain.wallet('user1');
      const user2 = chain.wallet('user2');
      
      // Submit a new proposal
      await chain.callContract(
          'crowdsourced-monument',
          'submit-proposal',
          [types.buff(32, '0123456789abcdef0123456789abcdef')],
          { sender: user1.address }
      );
      
      // Vote on the proposal
      let voteResult = await chain.callContract(
          'crowdsourced-monument',
          'vote',
          ['u1', true],
          { sender: user1.address }
      );
      expect(voteResult.result).toEqual(`(ok true)`, 'Voting should succeed');
      
      voteResult = await chain.callContract(
          'crowdsourced-monument',
          'vote',
          ['u1', false],
          { sender: user2.address }
      );
      expect(voteResult.result).toEqual(`(ok true)`, 'Voting should succeed');
      
      // Check the proposal details
      const proposal = await chain.getMap('proposals', 'u1');
      expect(proposal['yes-votes']).toEqual('1');
      expect(proposal['no-votes']).toEqual('1');
    });
  });
  
  // Add more test cases for other contract functions
});
