import { Provider, reduceEvents } from '@hyperledger/burrow';
import { padBytes, unprefixedHexString } from '@hyperledger/burrow/dist/convert';
import { Buffer } from 'buffer';
import { ErrorsLib } from '../commons-base/ErrorsLib.abi';
import { ERC165Utils } from '../commons-standards/ERC165Utils.abi';
import { Strings } from '../commons-utils/Strings.abi';
import { AgreementsAPI } from './AgreementsAPI.abi';
import { Completables } from './Completables.abi';
import { Completables as CompletablesV1 } from './Completables_v1_1_0.abi';

export type LogAgreementCompletableInit = CompletablesV1.SolidityEvent<'LogAgreementCompletableInit'>;
export type LogAgreementCompletableInitFranchisee =
  CompletablesV1.SolidityEvent<'LogAgreementCompletableInitFranchisee'>;
export type LogAgreementCompletableBegin = CompletablesV1.SolidityEvent<'LogAgreementCompletableBegin'>;
export type LogAgreementCompletableAttest = CompletablesV1.SolidityEvent<'LogAgreementCompletableAttest'>;
export type LogAgreementCompletableComplete = CompletablesV1.SolidityEvent<'LogAgreementCompletableComplete'>;

type Completable = LogAgreementCompletableInit & {
  franchisees: string[];
};

const COMPLETE_ON_RATIFICATION = 1;

export async function deployCompletables<T extends Completables.Contract | CompletablesV1.Contract>(
  client: Provider,
  deployContract: (client: Provider, agreementsAPI: string, errors: string, strings: string) => Promise<T>,
): Promise<T> {
  const [agreementsAPI, errors, strings] = await Promise.all([
    ERC165Utils.deploy(client).then((erc165Utils) => AgreementsAPI.deploy(client, erc165Utils)),
    ErrorsLib.deploy(client),
    Strings.deploy(client),
  ]);

  return deployContract(client, agreementsAPI, errors, strings);
}

export type MigrateOptions = {
  migrationParallelism: number;
  log?: (...args: any[]) => void;
};

const defaultMigrateOptions: MigrateOptions = {
  migrationParallelism: 100,
};

export async function migrateCompletables(
  client: Provider,
  src: CompletablesV1.Contract,
  dest: Completables.Contract,
  opts?: Partial<MigrateOptions>,
): Promise<void> {
  const { migrationParallelism, log } = { ...defaultMigrateOptions, ...opts };
  const buffer = new CompletableBuffer(dest, migrationParallelism);
  let index = 0;
  await reduceEvents(
    src.listener,
    // This only blocks when the buffer is full not on each function call which are parallelised
    (promise, event) => promise.then(() => processEvent(buffer, event, ++index, log)),
    Promise.resolve(),
    'first',
    'latest',
  );
  // Now we wait for all the function calls to complete
  await buffer.flush();
  // Turn events back on
  await dest.functions.activate();
}

async function processEvent(
  buffer: CompletableBuffer,
  // Future migrations will need to accept a union over all previous deployed completable versions
  event: CompletablesV1.TaggedPayload<CompletablesV1.EventName>,
  index: number,
  log?: (...args: any[]) => void,
): Promise<void> {
  if (log) {
    log(`Processing ${event.name} at height ${event.event.getHeader().getHeight()} (event ${index})`);
  }
  switch (event.name) {
    case 'LogAgreementCompletableInit': {
      buffer.init(event.payload);
      break;
    }
    case 'LogAgreementCompletableInitFranchisee': {
      buffer.initFranchisee(event.payload);
      break;
    }
    case 'LogAgreementCompletableBegin': {
      await buffer.begin(event.payload);
      break;
    }
    case 'LogAgreementCompletableAttest': {
      await buffer.attest(event.payload);
      break;
    }
    case 'LogAgreementCompletableComplete': {
      await buffer.complete(event.payload);
      break;
    }
  }
}

type IntervalID = string;

// The point of this class is to allow us to migrate multiple intervals in parallel (since they are independent) but
// to ensure the events for each interval arrive in the correct order to pass validation. At the same time we would like
// to work over the stream of events with bounded memory by flushing data from earlier events that have been consumed.
// To do this we maintain a buffer of promises of 'open work', we can control the level of parallelism with
// maxPromiseBufferSize which determines how many intervals we will be acting on in parallel before we need to block
// the migration to allow an entire thread of work against a particular interval to complete.
class CompletableBuffer {
  completables: Map<IntervalID, Completable> = new Map();
  promises: Map<IntervalID, Promise<IntervalID>> = new Map();

  constructor(private readonly dest: Completables.Contract, private readonly maxPromiseBufferSize: number) {}

  init(init: LogAgreementCompletableInit): void {
    const key = b32(init.intervalId);
    this.completables.set(key, { ...init, franchisees: [] });
  }

  initFranchisee(initFranchisee: LogAgreementCompletableInitFranchisee): void {
    const { intervalId, franchisee } = initFranchisee;
    const key = b32(intervalId);
    const comp = this.completables.get(key);
    if (!comp) {
      throw new Error(
        `Received LogAgreementCompletableInitFranchisee event before LogAgreementCompletableInit for interval ${key}}`,
      );
    }
    comp.franchisees.push(franchisee);
  }

  async begin(begin: LogAgreementCompletableBegin): Promise<void> {
    const { intervalId, agreementAddress, timestamp } = begin;
    const key = b32(intervalId);
    const comp = this.completables.get(key);
    if (!comp) {
      throw new Error(
        `Received LogAgreementCompletableBegin event before LogAgreementCompletableInit for interval ${key}}`,
      );
    }
    if (comp.agreementAddress !== agreementAddress) {
      throw new Error(
        `Received LogAgreementCompletableBegin for interval '${b32(
          intervalId,
        )}' with agreement address ${agreementAddress}, but corresponding LogAgreementCompletableInit has agreement address ${
          comp.agreementAddress
        }`,
      );
    }
    // We my have to block here if queue is full
    await this.enqueue(intervalId, async () => {
      try {
        await initCompletable(this.dest, comp);
        await this.dest.functions.begin(intervalId, timestamp);
      } catch (err) {
        throw new Error(`Could not init/begin ${b32(intervalId)}: ${err}`);
      }
    });
    // Remove from the completables buffer we don't need it anymore
    this.completables.delete(key);
  }

  async attest(attestation: LogAgreementCompletableAttest): Promise<void> {
    const { intervalId, timestamp, franchisee } = attestation;
    // The completable controller (us) is allowed to attest on behalf of any party only during migration (pre activate)
    return this.enqueue(intervalId, async () => {
      try {
        await this.dest.functions.attestAsParty(intervalId, timestamp, franchisee);
      } catch (err) {
        throw new Error(`Could not attest interval ${b32(intervalId)} for ${franchisee}: ${err}`);
      }
    });
  }

  async complete(completion: LogAgreementCompletableComplete): Promise<void> {
    const { intervalId, timestamp } = completion;
    const key = b32(intervalId);
    const comp = this.completables.get(key);
    await this.enqueue(intervalId, async () => {
      try {
        await this.dest.functions.complete(intervalId, timestamp);
      } catch (err) {
        throw new Error(`Could not complete interval ${b32(intervalId)}: ${err}`);
      }
    });
  }

  // Init any dangling completables (those that were init-ed but never begun)
  // TODO: the latest completables contract emits the number of franchisees with the init event so we won't need
  //   this workaround, we can juts flush when we see the last franchisee event
  async flush() {
    await Promise.all(Array.from(this.completables.values()).map((comp) => initCompletable(this.dest, comp)));
    // Let any remaining work finish
    await Promise.all(Array.from(this.promises.values()));
  }

  private async enqueue(intervalId: Buffer, work: () => Promise<unknown>): Promise<void> {
    const now = Date.now();
    const key = b32(intervalId);
    let promise = this.promises.get(key);
    if (!promise) {
      // Buffer is full we must wait for slot to free up
      if (this.promises.size >= this.maxPromiseBufferSize) {
        const finishedKey = await Promise.race(this.promises.values());
        if (!this.promises.has(finishedKey)) {
          // Sanity check
          throw new Error(`promise for interval ${finishedKey} not found to delete`);
        }
        // Free the slot
        this.promises.delete(finishedKey);
      }
      // Promise not established for interval, but we have space in buffer now, so allocate a new thread
      promise = Promise.resolve(key);
    }
    // Now we have a promise thread for the interval so enqueue work after current work
    this.promises.set(
      key,
      promise.then(work).then(() => key),
    );
  }
}

async function initCompletable(
  dest: Completables.Contract,
  { intervalId, agreementAddress, namespace, name, franchisees, threshold, metadata }: Completable,
): Promise<void> {
  await dest.functions.init(
    intervalId,
    namespace,
    name,
    agreementAddress,
    franchisees,
    threshold,
    // TODO: Completables v1 did not emit the options they were created with, v2 does so for future migrations this
    //  should be replaced with the options from the event
    COMPLETE_ON_RATIFICATION,
    metadata,
  );
}

function b32(buf: Buffer): string {
  return unprefixedHexString(padBytes(buf, 32));
}
