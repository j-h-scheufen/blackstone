import { config } from 'dotenv';
import { resolve } from 'path';
import { Deploy } from '../deploy';
import { Client } from '../lib/client';
import { NewContracts } from '../lib/contracts';

const minute = 60_000;

before(function (done) {
  this.timeout(5 * minute);
  config({ path: resolve(__dirname, '../../.env') });
  const client = new Client(process.env.CHAIN_URL_GRPC, process.env.SIGNING_ADDRESS);
  Deploy(client).then(() => done());
});

export function load() {
  config({ path: resolve(__dirname, '../../.env') });
  return NewContracts(process.env.CHAIN_URL_GRPC, process.env.SIGNING_ADDRESS, process.env.IDENTITY_PROVIDER);
}
