import { Client, Provider, readEvents } from '@hyperledger/burrow';
import { Buffer } from 'buffer';
import { expect } from 'chai';
import { ActiveAgreement } from '../agreements/ActiveAgreement.abi';
import { deployCompletables, migrateCompletables } from '../agreements/Completables';
import { Completables } from '../agreements/Completables.abi';
import { Completables as CompletablesV1 } from '../agreements/Completables_v1_1_0.abi';
import { padBytes } from '../bytes';
import { Organization } from '../commons-auth/Organization.abi';
import { UserAccount } from '../commons-auth/UserAccount.abi';
import { Contracts } from '../lib/contracts';
import { callOnBehalfOf, sha3, trimBufferPadding } from '../lib/utils';
import { client, contracts } from './before';

// TODO: generate enum
const COMPLETE_ON_RATIFICATION = 1;

describe('Completables', () => {
  it('Can create a completable and emit events', async () => {
    const height = await client.latestHeight();
    const completables = await deployCompletables(client, Completables.deployContract);
    const csf = completables.functions;
    await csf.activate();
    const {
      agreement,
      usersByName: { jemima, adrian, florence },
      users,
    } = await makeAgreement(client, contracts, height, 'jemima', 'adrian', 'florence');

    const id = b32(`foo_${height}`);
    await csf.init(
      id,
      'test',
      'comp1',
      agreement.address,
      users.map((u) => u.org.address),
      users.length,
      COMPLETE_ON_RATIFICATION,
      'meh',
    );

    await csf.begin(id, 1);

    let { isRatified } = await completables.functions.attestAsParty(
      id,
      2,
      jemima.org.address,
      callOnBehalfOf(jemima.user),
    );
    expect(isRatified).to.be.false;
    ({ isRatified } = await completables.functions.attestAsParty(
      id,
      3,
      florence.org.address,
      callOnBehalfOf(florence.user),
    ));
    expect(isRatified).to.be.false;
    ({ isRatified } = await completables.functions.attest(id, 4, callOnBehalfOf(adrian.user)));
    expect(isRatified).to.be.true;

    ({ isRatified } = await csf.complete(id, 10));
    expect(isRatified).to.be.true;

    // cs is a Completables contract object, listener is callback-accepting function that listens to all events
    // readEvents will read events into an array using a finite bounds and cleaning up connection and listeners
    // const logs = await readEvents(cs.listener);
    // Can specify block range start/end, defaults to:
    const logs = await readEvents(completables.listener, 'first', 'latest');

    // Can also stream using callback:
    completables.listener(
      (err, event) => {
        if (event.name === 'LogAgreementCompletableInitFranchisee') {
          // type narrowed
          // console.log(event.payload);
        }
      },
      'first',
      'stream',
    );

    // Also have a static event listener for each event (note we don't use classes or 'this' so we can pass all generated
    // functions around without binding):
    const inits = await readEvents(completables.listeners.LogAgreementCompletableInit);
    expect(inits.find(({ intervalId }) => !intervalId.equals(id))).undefined;
    // console.log(inits);
    // Or your own subset (union typed payload)
    const mixed = await readEvents(
      completables.listenerFor(['LogAgreementCompletableInit', 'LogAgreementCompletableComplete']),
    );
    expect(
      mixed.find((foo) => foo.name !== 'LogAgreementCompletableInit' && foo.name !== 'LogAgreementCompletableComplete'),
    ).undefined;

    // Filter on attests
    const attests = logs
      .filter(
        (l): l is Completables.TaggedPayload<'LogAgreementCompletableAttest'> =>
          // This autocompletes from union of this contract's events
          l.name === 'LogAgreementCompletableAttest',
      )
      .map((l) => ({
        // We can access the raw Burrow event and its metadata
        height: l.event.getHeader().getHeight(),
        // These are strongly typed LogAgreementCompletableAttest payloads
        payload: l.payload,
      }));
    expect(attests.find(({ payload }) => payload.ratified)).to.exist;
    // console.log(attests);
    // prints an array with elements like:
    //    {
    //     height: 632,
    //     payload: {
    //       eventId: '414E3A2F2F61677265656D656E742D636F6D706C657461626C65000000000000',
    //       intervalId: '666F6F5F36313700000000000000000000000000000000000000000000000000',
    //       agreementAddress: '83F1249EE094868AB8530133C1F56C2DC7F246B4',
    //       franchisee: '10E9C2D879A9C3587A9E9F8C960F801C80D531F3',
    //       ratified: false,
    //       timestamp: 2
    //     }
  });

  it('Completables v1 and v2 have equivalent traces', async () => {
    const completablesV1 = await deployCompletables(client, CompletablesV1.deployContract);
    const completablesV2 = await deployCompletables(client, Completables.deployContract);

    // TODO: run some shit on v1
    // Take a stream of completable calls against v1, then cut the deck at every possible point, take the sum
    // of v1 events before the cut and v2 events after the cut for each cut and assert the sum is always equivalent to
    // the original set of event

    await completablesV2.functions.activate();
    const height = await client.latestHeight();
    const agreement1 = await makeAgreement(client, contracts, height, 'fred', 'susan', 'miriam');
    const interval1 = b32('interval1');
    const interval2 = b32('interval2');
    const sequence = completablesSequence(
      agreement1,
      interval1,
      agreement1.users[0],
      'init',
      'begin',
      'attest',
      agreement1.users[1],
      'attest',
      agreement1.users[2],
      'attest',
      interval2,
      setThreshold(2),
      'init',
      'begin',
      'attest',
      agreement1.users[0],
      'attest',
      // Interval already complete
      failNext,
      'attest',
    );

    await runCompletablesSequence(completablesV1, sequence);
    await runCompletablesSequence(completablesV2, sequence);

    const v1Trace = await readEvents(completablesV1.listener);
    const v2Trace = await readEvents(completablesV2.listener);

    assertEquivalentTraces(v1Trace, v2Trace);
  });

  it('Can migrate from v1 to v2 Completables', async () => {
    const height = await client.latestHeight();
    const agreement1 = await makeAgreement(client, contracts, height, 'fred', 'susan', 'miriam');
    const interval1 = b32('monkeys');
    const interval2 = b32('badgers');
    const sequence = completablesSequence(
      agreement1,
      interval1,
      agreement1.users[0],
      'init',
      'begin',
      'attest',
      agreement1.users[1],
      'attest',
      agreement1.users[2],
      'attest',
      interval2,
      setThreshold(2),
      'init',
      'begin',
      'attest',
      agreement1.users[0],
      'attest',
    );

    const completablesV1 = await deployCompletables(client, CompletablesV1.deployContract);
    await runCompletablesSequence(completablesV1, sequence);
    const v1CompleteTrace = await readEvents(completablesV1.listener);

    // Now migrate at each possible height and check result is the same

    for (let i = 0; i < sequence.length; i++) {
      const completablesV1 = await deployCompletables(client, CompletablesV1.deployContract);

      const head = sequence.slice(0, i);
      const tail = sequence.slice(i);

      console.log(`head:\n${printSequence(head)}tail:\n${printSequence(tail)}`);
      try {
        await logTime('run head', () => runCompletablesSequence(completablesV1, head));
      } catch (err) {
        throw new Error(`could not run completables head sequence (position ${i}): ${printSequence(head)}: ${err}`);
      }
      const v1HeadTrace = await readEvents(completablesV1.listener);

      const completablesV2 = await deployCompletables(client, Completables.deployContract);
      try {
        await logTime('migrate completables', () => migrateCompletables(client, completablesV1, completablesV2));
      } catch (err) {
        throw new Error(
          `could not migrate completables at position ${i}, head sequence: ${printSequence(head)}: ${err}`,
        );
      }

      try {
        await logTime('run tail', () => runCompletablesSequence(completablesV2, tail));
      } catch (err) {
        throw new Error(`could not run completables tail sequence (position ${i}): ${printSequence(tail)}: ${err}`);
      }
      const v2TailTrace = await readEvents(completablesV2.listener);

      assertEquivalentTraces(v1CompleteTrace, [...v1HeadTrace, ...v2TailTrace], `at sequence bisection point ${i}`);
    }
  });
});

export type V1Event = CompletablesV1.TaggedPayload<CompletablesV1.EventName>;

export type V2Event = Completables.TaggedPayload<Completables.EventName>;

export function assertEquivalentTraces(v1Trace: V1Event[], v1v2Trace: (V1Event | V2Event)[], message?: string): void {
  expect(v1Trace.length).to.equal(v1v2Trace.length, message);
  for (let i = 0; i < v1Trace.length; i++) {
    assertEquivalentEvents(v1Trace[i], v1v2Trace[i], message);
  }
}

function assertEquivalentEvents(v1Event: V1Event, v1v2Event: V1Event | V2Event, message?: string) {
  expect(v1Event.name).to.equal(v1v2Event.name, message);
  // We have added some properties to the v2 init event, but all v1 properties should match
  expect(v1v2Event.payload).to.deep.contain(v1Event.payload, message);
}

type CompletableAction = {
  name: 'init' | 'begin' | 'attest' | 'complete';
  intervalId: Buffer;
  party: PartyUser;
  agreement: PartyAgreement;
  timestamp: number;
  threshold: number;
  shouldFail: boolean;
};

// Sequence instructions
type Threshold = number;
type IntervalID = Buffer;
const failNext = Symbol('failNext');
type FailNext = typeof failNext;
type SequenceArg = CompletableAction['name'] | IntervalID | Threshold | PartyAgreement | PartyUser | FailNext;
function setThreshold(n: number): Threshold {
  return n;
}

// Helper for constructing a synthetic sequence of completable events, i.e. a completables execution
function completablesSequence(
  agreement: PartyAgreement,
  intervalId: Buffer,
  party: PartyUser,
  ...sequence: SequenceArg[]
): CompletableAction[] {
  const actions: CompletableAction[] = [];
  let timestamp = 1;
  let threshold = agreement.users.length;
  let shouldFail = false;
  for (const arg of sequence) {
    if (typeof arg === 'string') {
      // Push action
      actions.push({ name: arg, intervalId, threshold, agreement, party, timestamp, shouldFail });
      shouldFail = false;
      // Set context for next action
    } else if (typeof arg === 'number') {
      threshold = arg;
    } else if (arg instanceof Buffer) {
      intervalId = arg;
    } else if (arg === failNext) {
      shouldFail = true;
    } else if (arg.type === 'PartyUser') {
      party = arg;
    } else if (arg.type === 'PartyAgreement') {
      agreement = arg;
      threshold = agreement.users.length;
    }
    timestamp += 1;
  }
  return actions;
}

function printSequence(sequence: CompletableAction[]): string {
  if (!sequence.length) {
    return 'nil\n';
  }
  let buf = '';

  for (const action of sequence) {
    const {
      agreement: {
        agreement: { address },
      },
      name,
      party: { user, org },
      shouldFail,
    } = action;
    const intervalId = trimBufferPadding(action.intervalId).toString('hex');
    buf += `[${address}]\t[${intervalId}]\t${name}\t(user: ${user.address}\torg: ${org.address})`;
    if (shouldFail) {
      buf += ' (expected to fail)';
    }
    buf += '\n';
  }
  return buf;
}

async function runCompletablesSequence<T extends Completables.Contract | CompletablesV1.Contract>(
  completables: T,
  sequence: CompletableAction[],
): Promise<void> {
  for (const action of sequence) {
    try {
      await runAction(completables, action);
    } catch (err) {
      if (!action.shouldFail) {
        throw new Error(`Could not run completables sequence: ${err}`);
      }
    }
  }
}

async function runAction<T extends Completables.Contract | CompletablesV1.Contract>(
  completables: T,
  action: CompletableAction,
): Promise<void> {
  const { intervalId, timestamp, threshold } = action;
  switch (action.name) {
    case 'init': {
      const {
        agreement: { agreement, users },
      } = action;
      await completables.functions.init(
        intervalId,
        'test',
        'comp1',
        agreement.address,
        users.map((u) => u.org.address),
        threshold,
        COMPLETE_ON_RATIFICATION,
        'meh',
      );
      break;
    }
    case 'begin': {
      await completables.functions.begin(intervalId, timestamp);
      break;
    }
    case 'attest': {
      const { party } = action;
      // Note: V1 and V2 both have an overlapping definition of attest, but V1 does not have attestAsParty so we
      //  can't use that here
      await completables.functions.attest(intervalId, timestamp, callOnBehalfOf(party.user));
      break;
    }
    case 'complete': {
      await completables.functions.complete(intervalId, timestamp);
      break;
    }
  }
}

// TODO: probably factor these test helpers out to their own file(s)

type PartyUser = {
  type: 'PartyUser';
  name: string;
  id: string;
  user: UserAccount.Contract;
  org: Organization.Contract;
};

type PartyAgreement<T extends string = string> = {
  type: 'PartyAgreement';
  agreement: ActiveAgreement.Contract;
  usersByName: Record<T, PartyUser>;
  users: PartyUser[];
};

async function makeAgreement<T extends string>(
  client: Client,
  contracts: Contracts,
  nonce: number,
  ...names: T[]
): Promise<PartyAgreement<T>> {
  const usersByName = await makeUsers(client, nonce, ...names);
  const users = Object.values<PartyUser>(usersByName);
  const agreement = await createAgreement(client, contracts, users);
  return {
    type: 'PartyAgreement',
    agreement,
    usersByName,
    users,
  };
}

async function logTime<T>(name: string, fn: () => Promise<T>): Promise<T> {
  const start = Date.now();
  const result = await fn();
  const elapsed = Date.now() - start;
  console.log(`${name} took ${elapsed}ms`);
  return result;
}

async function makeUsers<T extends string>(
  client: Client,
  nonce: number,
  ...names: T[]
): Promise<Record<T, PartyUser>> {
  const entries = await Promise.all<[T, PartyUser]>(names.map((n) => makeUser(client, n, nonce).then((u) => [n, u])));
  return entries.reduce((acc, [n, p]) => ({ ...acc, [n]: p }), {} as Record<T, PartyUser>);
}

async function makeUser(client: Client, name: string, height?: number): Promise<PartyUser> {
  if (height) {
    name += '_' + height;
  }
  const id = sha3(name);
  const user = UserAccount.contract(client, await contracts.createUser({ username: id }));
  const org = Organization.contract(client, await contracts.createOrganization({ approvers: [user.address] }));
  const { successful } = await org.functions.addUser(user.address);
  if (!successful) {
    throw new Error(`adding user ${name} to organisation ${org.address} unsuccessful`);
  }
  return {
    type: 'PartyUser',
    name,
    id,
    user,
    org,
  };
}

async function createAgreement(
  client: Provider,
  contracts: Contracts,
  users: PartyUser[],
): Promise<ActiveAgreement.Contract> {
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
  return ActiveAgreement.contract(
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

function b32(str: string): Buffer {
  return padBytes(Buffer.from(str), 32);
}
