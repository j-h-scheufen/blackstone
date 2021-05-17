import { Client } from '@hyperledger/burrow';
import { deployCompletables, migrateCompletables } from '../agreements/Completables';
import { Completables } from '../agreements/Completables.abi';
import { Completables as CompletablesV1 } from '../agreements/Completables_v1_1_0.abi';
import { DOUG } from '../commons-management/DOUG.abi';

const client = new Client('127.0.0.1:10997', 'E49DE2603A7E5B02B7AE2F8C1B95E369F85DB4A2');

// Just a little script for testing migrations
async function main(): Promise<void> {
  const entry = await client.namereg.get('DOUG');
  const doug = DOUG.contract(client, entry.getData());
  const { contractAddress } = await doug.functions.lookup('Completables');
  const completablesV1 = CompletablesV1.contract(client, contractAddress);
  const completablesV2 = await deployCompletables(client, Completables.deployContract);
  await migrateCompletables(client, completablesV1, completablesV2, { log: (...args) => console.log(...args) });
}

main().then(
  () => console.log('done'),
  (err) => {
    console.error(`error migrating: ${err}`);
  },
);
