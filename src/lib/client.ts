import { Burrow } from '@hyperledger/burrow';
import { abiToBurrowResult, burrowToAbiResult, unprefixedHexString } from '@hyperledger/burrow/dist/convert';
import { TxExecution } from '@hyperledger/burrow/proto/exec_pb';
import { CallTx, TxInput } from '@hyperledger/burrow/proto/payload_pb';
import { StatusParam } from '@hyperledger/burrow/proto/rpcquery_pb';
import { ResultStatus } from '@hyperledger/burrow/proto/rpc_pb';
import { AbiCoder, ParamType } from 'ethers/lib/utils';
import { Readable } from 'stream';
import { padBytesNN } from '../bytes';

export type Interceptor = (result: TxExecution) => Promise<TxExecution>;

// TODO[Silas]: use the vanilla Burrow client rather than this shim when extending/replacing codegen from solts
export class Client {
  interceptor: Interceptor;

  public readonly burrow: Burrow;

  private readonly coder = new AbiCoder();

  constructor(url: string, account: string) {
    this.burrow = new Burrow(url, account);

    // NOTE: in general interceptor may be async
    this.interceptor = async (data) => data;
  }

  status(): Promise<ResultStatus> {
    return new Promise((resolve, reject) =>
      this.burrow.query.status(new StatusParam(), (err, resp) => (err ? reject(err) : resolve(resp))),
    );
  }

  deploy(msg: CallTx, callback: (err: Error, addr: Uint8Array) => void): void {
    this.burrow
      .call(msg)
      .then((txe) => this.interceptor(txe))
      .then(
        (txe) => callback(undefined, txe.getReceipt().getContractaddress_asU8()),
        (err) => callback(err, undefined),
      );
  }

  call(msg: CallTx, callback: (err: Error, exec: Uint8Array) => void): void {
    this.burrow
      .call(msg)
      .then((txe) => this.interceptor(txe))
      .then(
        (txe) => callback(undefined, txe.getResult().getReturn_asU8()),
        (err) => callback(err, undefined),
      );
  }

  callSim(msg: CallTx, callback: (err: Error, exec: Uint8Array) => void): void {
    this.burrow.callSim(msg).then(
      (txe) => callback(undefined, txe.getResult().getReturn_asU8()),
      (err) => callback(err, undefined),
    );
  }

  listen(signature: string, address: string, callback: (err: Error, event: any) => void): Readable {
    return this.burrow.listen(signature, address, callback);
  }

  payload(data: string, address?: string): CallTx {
    const input = new TxInput();
    input.setAddress(Buffer.from(this.burrow.account, 'hex'));
    input.setAmount(0);

    const payload = new CallTx();
    payload.setInput(input);
    if (address) {
      payload.setAddress(Buffer.from(address, 'hex'));
    }
    payload.setGaslimit(1000000);
    payload.setFee(0);
    payload.setData(Buffer.from(data, 'hex'));

    return payload;
  }

  encode(name: string, inputs: string[], ...args: any[]): string {
    try {
      padBytesNN(inputs, args);
      const types = inputs.map((i) => ParamType.from(i));
      const values = burrowToAbiResult(args, types);
      return name + unprefixedHexString(this.coder.encode(types, values));
    } catch (err) {
      throw new Error(`Blackstone Client could not encode call to '${name}', inputs: ${inputs}, args: ${args}: ${err}`);
    }
  }

  decode(data: Uint8Array, outputs: string[]): any {
    try {
      const types = outputs.map((o) => ParamType.from(o));
      return abiToBurrowResult(this.coder.decode(types, Buffer.from(data)), types);
    } catch (err) {
      throw new Error(`Blackstone Client could not decode result, data: ${data}, outputs: ${outputs}: ${err}`);
    }
  }
}
