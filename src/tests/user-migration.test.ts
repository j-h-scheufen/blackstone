import * as chai from 'chai';
import chaiAsPromised from 'chai-as-promised';
import nanoid from 'nanoid';
import rid from 'random-id';
import { sha3 } from '../lib/utils';
import { contracts } from './before';
chai.use(chaiAsPromised);
const { expect } = chai;

describe('USER MIGRATION', () => {
  const user = {
    userid: `monax_test|${nanoid()}`,
    useridHash: '',
    username: `${rid(5, 'aA0')}`,
    usernameHash: '',
    address: '',
  };

  it('Should create a user account', async () => {
    user.usernameHash = sha3(user.username);
    const address = await contracts.createUser({
      username: user.usernameHash,
    });
    expect(address).to.match(/[0-9A-Fa-f]{40}/);
    user.address = address;
  }).timeout(10000);

  it('Should migrate user account from username to userid', async () => {
    user.useridHash = sha3(user.userid);
    await contracts.migrateUserAccountInEcosystem(user.address, user.usernameHash, user.useridHash);
    const address = await contracts.getUserByUserId(user.useridHash);
    expect(user.address).to.equal(address);
  }).timeout(10000);
});
