import { Caller, Client, Provider } from '@hyperledger/burrow';
import { Buffer } from 'buffer';
import { Keccak } from 'sha3';
import { UserAccount } from '../commons-auth/UserAccount.abi';

const GRPC_NOT_FOUND = 5;

export function trimBufferPadding(buf: Buffer): Buffer{
  let lo = 0;
  let hi = buf.length;
  for (let i = 0; i < buf.length && buf[i] === 0; i += 1) {
    lo = i + 1;
  }
  for (let i = buf.length - 1; i > 0 && buf[i] === 0; i -= 1) {
    hi = i;
  }
  return buf.slice(lo, hi);
}

export function bytesFromString(str: string): Buffer {
  return Buffer.from(str, 'utf8');
}

export function bytesToString(data: Buffer): string {
  return trimBufferPadding(data).toString('utf8');
}

export function decodeHex(str: string): Buffer {
  return Buffer.from(str, 'hex');
}

export function encodeHex(data: Buffer): string {
  return data.toString('hex');
}

export function callOnBehalfOf(user: UserAccount.Contract | string): Caller {
  return async <Output>(
    client: Provider,
    address: string,
    data: Uint8Array,
    isSim: boolean,
    callback: (returnBytes: Uint8Array) => Output,
  ): Promise<Output> => {
    if (typeof user === 'string') {
      user = UserAccount.contract(client, user);
    }
    const { returnData } = await user.functions.forwardCall(address, Buffer.from(data));
    return callback(returnData);
  };
}

export async function getFromNameRegistry(client: Client, name: string): Promise<string | void> {
  try {
    const entry = await client.namereg.get(name);
    return entry.getData();
  } catch (err) {
    if (err.code === GRPC_NOT_FOUND) {
      return undefined;
    }
    throw err;
  }
}

export async function setInNameRegistry(client: Client, name: string, value: string): Promise<void> {
  await client.namereg.set(name, value);
}

export function sha3(str: string): string {
  const hash = new Keccak(256).update(str);
  return hash.digest('hex').toUpperCase();
}
