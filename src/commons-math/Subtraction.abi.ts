//Code generated by solts. DO NOT EDIT.
import { Readable } from "stream";
interface Provider<Tx> {
    deploy(msg: Tx, callback: (err: Error, addr: Uint8Array) => void): void;
    call(msg: Tx, callback: (err: Error, exec: Uint8Array) => void): void;
    callSim(msg: Tx, callback: (err: Error, exec: Uint8Array) => void): void;
    listen(signature: string, address: string, callback: (err: Error, event: any) => void): Readable;
    payload(data: string, address?: string): Tx;
    encode(name: string, inputs: string[], ...args: any[]): string;
    decode(data: Uint8Array, outputs: string[]): any;
}
function Call<Tx, Output>(client: Provider<Tx>, addr: string, data: string, isSim: boolean, callback: (exec: Uint8Array) => Output): Promise<Output> {
    const payload = client.payload(data, addr);
    if (isSim)
        return new Promise((resolve, reject) => { client.callSim(payload, (err, exec) => { err ? reject(err) : resolve(callback(exec)); }); });
    else
        return new Promise((resolve, reject) => { client.call(payload, (err, exec) => { err ? reject(err) : resolve(callback(exec)); }); });
}
function Replace(bytecode: string, name: string, address: string): string {
    address = address + Array(40 - address.length + 1).join("0");
    const truncated = name.slice(0, 36);
    const label = "__" + truncated + Array(37 - truncated.length).join("_") + "__";
    while (bytecode.indexOf(label) >= 0)
        bytecode = bytecode.replace(label, address);
    return bytecode;
}
export module Subtraction {
    export function Deploy<Tx>(client: Provider<Tx>): Promise<string> {
        let bytecode = "608060405234801561001057600080fd5b506102f6806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063867c715114610030575b600080fd5b6100a66004803603608081101561004657600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506100a8565b005b60008473ffffffffffffffffffffffffffffffffffffffff1663c2334a5a856040518263ffffffff1660e01b815260040180828152602001807f6e756d626572496e4f6e65000000000000000000000000000000000000000000815250602001915050602060405180830381600087803b15801561012557600080fd5b505af1158015610139573d6000803e3d6000fd5b505050506040513d602081101561014f57600080fd5b8101908080519060200190929190505050905060008573ffffffffffffffffffffffffffffffffffffffff1663c2334a5a866040518263ffffffff1660e01b815260040180828152602001807f6e756d626572496e54776f000000000000000000000000000000000000000000815250602001915050602060405180830381600087803b1580156101df57600080fd5b505af11580156101f3573d6000803e3d6000fd5b505050506040513d602081101561020957600080fd5b810190808051906020019092919050505090508573ffffffffffffffffffffffffffffffffffffffff16632a819af7868385036040518363ffffffff1660e01b815260040180838152602001807f6e756d6265724f7574000000000000000000000000000000000000000000000081525060200182815260200192505050600060405180830381600087803b1580156102a157600080fd5b505af11580156102b5573d6000803e3d6000fd5b5050505050505050505056fea265627a7a7231582071b85d112ce7284b7a6206b46da6c4410eb995d37ab742bb2e554bb8779de31564736f6c634300050c0032";
        const data = bytecode;
        const payload = client.payload(data);
        return new Promise((resolve, reject) => { client.deploy(payload, (err, addr) => {
            if (err)
                reject(err);
            else {
                const address = Buffer.from(addr).toString("hex").toUpperCase();
                resolve(address);
            }
        }); });
    }
    export class Contract<Tx> {
        private client: Provider<Tx>;
        public address: string;
        constructor(client: Provider<Tx>, address: string) {
            this.client = client;
            this.address = address;
        }
        complete(_piAddress: string, _activityInstanceId: Buffer) {
            const data = Encode(this.client).complete(_piAddress, _activityInstanceId);
            return Call<Tx, void>(this.client, this.address, data, false, (exec: Uint8Array) => {
                return Decode(this.client, exec).complete();
            });
        }
    }
    export const Encode = <Tx>(client: Provider<Tx>) => { return {
        complete: (_piAddress: string, _activityInstanceId: Buffer) => { return client.encode("867C7151", ["address", "bytes32"], _piAddress, _activityInstanceId); }
    }; };
    export const Decode = <Tx>(client: Provider<Tx>, data: Uint8Array) => { return {
        complete: (): void => { return; }
    }; };
}