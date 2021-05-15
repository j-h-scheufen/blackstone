import { CallTx } from '@hyperledger/burrow/proto/payload_pb';
import { expect } from 'chai';
import { ActiveAgreement } from '../agreements/ActiveAgreement.abi';
import { AgreementsAPI } from '../agreements/AgreementsAPI.abi';
import { Completables } from '../agreements/Completables.abi';
import { padBytes } from '../bytes';
import { Organization } from '../commons-auth/Organization.abi';
import { UserAccount } from '../commons-auth/UserAccount.abi';
import { ErrorsLib } from '../commons-base/ErrorsLib.abi';
import { ERC165Utils } from '../commons-standards/ERC165Utils.abi';
import { Strings } from '../commons-utils/Strings.abi';
import { Client } from '../lib/client';
import { Contracts } from '../lib/contracts';
import { readEventLog } from '../lib/events';
import { sha3 } from '../lib/utils';
import { client, contracts } from './before';

// TODO: generate enum
const COMPLETE_ON_RATIFICATION = 1;

let height: number;

const signatureLogAgreementCompletableAttest =
  'LogAgreementCompletableAttest(bytes32,bytes32,address,address,bool,int256)';
// const signatureLogAgreementCompletableAttest = 'LogAgreementCompletableAttest';

describe('Completables', () => {
  before(async () => {
    const status = await client.status();
    height = status.getSyncinfo().getLatestblockheight();
  });

  it('Creates a Completable', async () => {
    const cs = await newCompletables(client);
    await cs.activate();
    const userRecord = await makeUsers(client, height, 'jemima', 'adrian', 'florence');
    const { jemima, adrian, florence } = userRecord;
    const users = Object.values(userRecord);
    const agreement = await createAgreement(client, contracts, users);
    const id = b32(`foo_${height}`);
    await cs.init(
      id,
      'test',
      'comp1',
      agreement.address,
      users.map((u) => u.org.address),
      users.length,
      COMPLETE_ON_RATIFICATION,
      'meh',
    );

    await cs.begin(id, 1);

    const nonParty = await makeUser(client, 'non-user', height);

    let isRatified = await attest(client, cs, jemima.user, id, 2, jemima.org.address);
    expect(isRatified).to.be.false;
    isRatified = await attest(client, cs, florence.user, id, 3);
    expect(isRatified).to.be.false;
    isRatified = await attest(client, cs, adrian.user, id, 4);
    expect(isRatified).to.be.true;

    ({ isRatified } = await cs.complete(id, 10));
    expect(isRatified).to.be.true;
    // const decode = Completables.Decode(client);
    const foo = 2;

    const signature = sha3(signatureLogAgreementCompletableAttest);
    const logs = await readEventLog(cs.address, signature, 3);
    console.log(logs);

    // TODO: provider a strongly typed listener interface with functions <EventName>(types...) that we can call with each decoded event
  });
});

async function attest(
  client: Client,
  cs: Completables.Contract<CallTx>,
  user: UserAccount.Contract<CallTx>,
  intervalId: Buffer,
  timestamp: number,
  partyAddress?: string,
): Promise<boolean> {
  const encode = Completables.Encode(client);
  const payload = partyAddress
    ? encode.attestAsParty(intervalId, timestamp, partyAddress)
    : encode.attest(intervalId, timestamp);
  const { returnData } = await user.forwardCall(cs.address, Buffer.from(payload, 'hex'));
  console.log(`return: ${returnData.toString('hex')}`);
  const decode = Completables.Decode(client, returnData);
  const { isRatified } = partyAddress ? decode.attestAsParty() : decode.attest();
  console.log(isRatified);
  return isRatified;
}

type PartyUser = {
  name: string;
  id: string;
  user: UserAccount.Contract<CallTx>;
  org: Organization.Contract<CallTx>;
};

async function makeUsers<T extends string>(
  client: Client,
  nonce: number,
  ...names: T[]
): Promise<Record<string, PartyUser>> {
  const entries = await Promise.all<[T, PartyUser]>(names.map((n) => makeUser(client, n, nonce).then((u) => [n, u])));
  return entries.reduce((acc, [n, p]) => ({ ...acc, [n]: p }), {} as Record<string, PartyUser>);
}

async function makeUser(client: Client, name: string, height?: number): Promise<PartyUser> {
  if (height) {
    name += '_' + height;
  }
  const id = sha3(name);
  const user = new UserAccount.Contract(client, await contracts.createUser({ username: id }));
  const org = new Organization.Contract(client, await contracts.createOrganization({ approvers: [user.address] }));
  const { successful } = await org.addUser(user.address);
  if (!successful) {
    throw new Error(`adding user ${name} to organisation ${org.address} unsuccessful`);
  }
  return {
    name,
    id,
    user,
    org,
  };
}

async function createAgreement(
  client: Client,
  contracts: Contracts,
  users: PartyUser[],
): Promise<ActiveAgreement.Contract<CallTx>> {
  const [owner] = users;
  const archetype = await contracts.createArchetype({
    price: 10,
    active: true,
    author: owner.user.address,
    owner: owner.user.address,
    formationProcess: '',
    executionProcess: '',
    packageId: '',
    governingArchetypes: [],
  });
  return new ActiveAgreement.Contract(
    client,
    await contracts.createAgreement({
      archetype,
      creator: owner.user.address,
      owner: owner.user.address,
      privateParametersFileReference: '',
      parties: users.map((u) => u.org.address),
      collectionId: '',
      governingAgreements: [],
    }),
  );
}

async function newCompletables(client: Client): Promise<Completables.Contract<CallTx>> {
  const [agreementsAPI, errors, strings] = await Promise.all([
    ERC165Utils.Deploy(client).then((erc165Utils) => AgreementsAPI.Deploy(client, erc165Utils)),
    ErrorsLib.Deploy(client),
    Strings.Deploy(client),
  ]);

  const completables = await Completables.Deploy(client, agreementsAPI, errors, strings);
  return new Completables.Contract(client, completables);
}

function b32(str: string): Buffer {
  return padBytes(Buffer.from(str), 32);
}
