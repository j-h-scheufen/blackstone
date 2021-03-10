import {Migrations} from "../migrations/Migrations.abi";
import {config} from "dotenv";
import {resolve} from "path";
import {Client} from "..";
import {Strings} from "../commons-utils/Strings.abi";
import {CallTx} from "@hyperledger/burrow/proto/payload_pb";
import { expect } from "chai";

describe('Migrations', () => {
  let migrations: Migrations.Contract<CallTx>;

  before(async () => {
    config({path: resolve(__dirname, "../../.env")})
    const signingaddress = process.env.SIGNING_ADDRESS;
    const client = new Client(process.env.CHAIN_URL_GRPC, signingaddress);
    const stringsAddress = await Strings.Deploy(client);
    migrations = new Migrations.Contract(client, await Migrations.Deploy(client, stringsAddress))
  });

  it('migrates', async () => {
    await migrations.migrate("foo", 1);
    await assertRejects(() => migrations.migrate("foo", 1), 'should be at index 2');
    await assertRejects(() => migrations.migrate("foo", 2), 'already exists');
    const [index] = await migrations.head();
    await migrations.migrate("bar", index+1)
    await assertRejects(() => migrations.migrate("frogs", 999), 'should be at index 3')
  })

  it('gets migration', async () => {
    const [head] = await migrations.head();
    await assertRejects(() => migrations.migrationAt(head+1), 'cannot return migration at index 3')
    await migrations.migrationAt(head)
    const name = 'flob'
    await migrations.migrate(name, head+1)
    const [index, nameOut] = await migrations.migrationByName(name)
    expect(index).to.equal(head+1)
    expect(nameOut).to.equal(name)
  })
})

export async function assertRejects(method: () => Promise<unknown>, errorMessageFragment?: string): Promise<void> {
  let error = null;
  try {
    await method();
  } catch (err) {
    error = err;
  }
  if (!error) {
    throw new Error('An error was expected but none occurred')
  }
  const message = error?.message;
  if (errorMessageFragment && !message?.includes(errorMessageFragment)) {
    throw new Error(`Expected error message to include '${errorMessageFragment}' error message was: '${message}'`)
  }
}
