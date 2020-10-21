import {Migrations} from "../migrations/Migrations.abi";
import {config} from "dotenv";
import {resolve} from "path";
import {Client} from "..";
import {Strings} from "../commons-utils/Strings.abi";
import {CallTx} from "@hyperledger/burrow/proto/payload_pb";

describe('Migrations', () => {
  let migrations: Migrations.Contract<CallTx>;

  before(async () => {
    config({path: resolve(__dirname, "../../.env")})
    const client = new Client(process.env.CHAIN_URL_GRPC, process.env.SIGNING_ADDRESS);
    migrations = new Migrations.Contract(client, await Migrations.Deploy(client, await Strings.Deploy(client)))
  });

  it('migrates', async () => {
    await migrations.migrate("foo", 1);
    await assertRejects(() => migrations.migrate("foo", 1), 'should be at index 2');
    await assertRejects(() => migrations.migrate("foo", 2), 'already exists');
    const [index] = await migrations.head();
    await migrations.migrate("bar", index+1)
    await assertRejects(() => migrations.migrate("frogs", 999), 'should be at index 3')
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
