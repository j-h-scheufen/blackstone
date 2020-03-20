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
export module MakeZero {
    export function Deploy<Tx>(client: Provider<Tx>): Promise<string> {
        let bytecode = "608060405234801561001057600080fd5b5061017f806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063867c715114610030575b600080fd5b6100a66004803603608081101561004657600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506100a8565b005b8373ffffffffffffffffffffffffffffffffffffffff16632a819af78460006040518363ffffffff1660e01b815260040180838152602001807f6e756d6265724f7574000000000000000000000000000000000000000000000081525060200182815260200192505050600060405180830381600087803b15801561012c57600080fd5b505af1158015610140573d6000803e3d6000fd5b505050505050505056fea265627a7a72315820b473720f0a771007667ea3b8727ed06dde091fd6f4b4ee74bcda81e12061733464736f6c634300050c0032";
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