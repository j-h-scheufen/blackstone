import { Client } from '@hyperledger/burrow';
import { config } from 'dotenv';
import { resolve } from 'path';
import { Deploy } from '../deploy';
import { Contracts, NewContracts } from '../lib/contracts';

const minute = 60_000;

config({ path: resolve(__dirname, '../../.env') });
export const client = new Client(process.env.CHAIN_URL_GRPC, process.env.SIGNING_ADDRESS);
export let contracts: Contracts;

before(async function () {
  this.timeout(5 * minute);
  await Deploy(client);
  contracts = await NewContracts(
    process.env.CHAIN_URL_GRPC,
    process.env.SIGNING_ADDRESS,
    process.env.IDENTITY_PROVIDER,
  );
});
