import { toBuffer } from '@hyperledger/burrow/dist/convert';

const bytesNN = /bytes([0-9]+)/;
const zeroAddress = '0x0000000000000000000000000000000000000000';

// Hack: ethers AbiCoder is strict about the length of things it expects (in particular the byte width of bytesNN) but
// we rely on early ABI encoders padding values for us, we also use empty string for the zero address
export function padBytesNN(types: string[], values: unknown[]): void {
  if (types.length !== values.length) {
    throw new Error(`padBytesByABI requires same number of values (${values}) as types (${types})`);
  }
  for (let i = 0; i < types.length; i++) {
    const type = types[i];
    const value = values[i];
    const match = bytesNN.exec(type);
    if (match) {
      values[i] = recApply((input) => {
        if (typeof input !== 'string' && !(input instanceof Uint8Array)) {
          throw new Error(`type at index ${i} is ${type} but value ${value} is not Uint8Array`);
        }
        return padBytes(input, Number(match[1]));
      }, value);
    } else if (type === 'address' && (value === '0x0' || !value)) {
      values[i] = zeroAddress;
    }
  }
}

export function padBytes(buf: Uint8Array | string, n: number): Buffer {
  if (typeof buf === 'string') {
    // Parse hex (possible 0x prefixed) into bytes!
    buf = toBuffer(buf);
  }
  if (buf.length > n) {
    throw new Error(`cannot pad buffer ${buf} of length ${buf.length} to ${n} because it is longer than ${n}`);
  }
  const padded = Buffer.alloc(n);
  Buffer.from(buf).copy(padded);
  return padded;
}

type NestedArray<T> = T | NestedArray<T>[];

// Recursively applies func to an arbitrarily nested array with a single element type as described by solidity tuples
function recApply(func: (input: unknown) => unknown, args: NestedArray<unknown>): NestedArray<unknown> {
  return Array.isArray(args) ? args.map((arg) => recApply(func, arg)) : func(args);
}
