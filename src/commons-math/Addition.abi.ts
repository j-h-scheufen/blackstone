//Code generated by solts. DO NOT EDIT.
import { Readable } from "stream";
import { Address, CallTx, ContractCodec, Signal, Event, EventStream, listenerFor, Result } from "@hyperledger/burrow";
interface Provider {
    deploy(msg: CallTx): Promise<Address>;
    call(msg: CallTx): Promise<Uint8Array | undefined>;
    callSim(msg: CallTx): Promise<Uint8Array | undefined>;
    listen(signatures: string[], address: string, callback: (err?: Error, event?: Event) => Signal | void, start?: "first" | "latest" | "stream" | number, end?: "first" | "latest" | "stream" | number): EventStream;
    payload(data: string | Uint8Array, address?: string): CallTx;
    contractCodec(contractABI: string): ContractCodec;
}
export type Caller = typeof defaultCall;
export async function defaultCall<Output>(client: Provider, addr: string, data: Uint8Array, isSim: boolean, callback: (returnData: Uint8Array | undefined) => Output): Promise<Output> {
    const payload = client.payload(data, addr);
    const returnData = await (isSim ? client.callSim(payload) : client.call(payload));
    return callback(returnData);
}
function linker(bytecode: string, name: string, address: string): string {
    address = address + Array(40 - address.length + 1).join("0");
    const truncated = name.slice(0, 36);
    const label = "__" + truncated + Array(37 - truncated.length).join("_") + "__";
    while (bytecode.indexOf(label) >= 0)
        bytecode = bytecode.replace(label, address);
    return bytecode;
}
export module Addition {
    export const contactName = "Addition";
    export const abi = '[{"constant":false,"inputs":[{"internalType":"address","name":"_piAddress","type":"address"},{"internalType":"bytes32","name":"_activityInstanceId","type":"bytes32"},{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"address","name":"","type":"address"}],"name":"complete","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
    export const bytecode = '608060405234801561001057600080fd5b506102f6806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063867c715114610030575b600080fd5b6100a66004803603608081101561004657600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506100a8565b005b60008473ffffffffffffffffffffffffffffffffffffffff1663c2334a5a856040518263ffffffff1660e01b815260040180828152602001807f6e756d626572496e4f6e65000000000000000000000000000000000000000000815250602001915050602060405180830381600087803b15801561012557600080fd5b505af1158015610139573d6000803e3d6000fd5b505050506040513d602081101561014f57600080fd5b8101908080519060200190929190505050905060008573ffffffffffffffffffffffffffffffffffffffff1663c2334a5a866040518263ffffffff1660e01b815260040180828152602001807f6e756d626572496e54776f000000000000000000000000000000000000000000815250602001915050602060405180830381600087803b1580156101df57600080fd5b505af11580156101f3573d6000803e3d6000fd5b505050506040513d602081101561020957600080fd5b810190808051906020019092919050505090508573ffffffffffffffffffffffffffffffffffffffff16632a819af7868385016040518363ffffffff1660e01b815260040180838152602001807f6e756d6265724f7574000000000000000000000000000000000000000000000081525060200182815260200192505050600060405180830381600087803b1580156102a157600080fd5b505af11580156102b5573d6000803e3d6000fd5b5050505050505050505056fea265627a7a723158205ee947df9e03f41da67bc26b9fa067292658d68724a41fead276b6aac7447cdb64736f6c63430005110032';
    export function deploy(client: Provider): Promise<string> {
        const codec = client.contractCodec(abi);
        let linkedBytecode = bytecode;
        const data = Buffer.concat([Buffer.from(linkedBytecode, "hex"), codec.encodeDeploy()]);
        const payload = client.payload(data);
        return client.deploy(payload);
    }
    export async function deployContract(client: Provider): Promise<Contract> { const address = await deploy(client); return contract(client, address); }
    export type Contract = ReturnType<typeof contract>;
    export const contract = (client: Provider, address: string) => ({ address, functions: { complete(_piAddress: string, _activityInstanceId: Buffer, call = defaultCall): Promise<void> {
                const data = encode(client).complete(_piAddress, _activityInstanceId);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).complete();
                });
            } } as const } as const);
    export const encode = (client: Provider) => { const codec = client.contractCodec(abi); return {
        complete: (_piAddress: string, _activityInstanceId: Buffer) => { return codec.encodeFunctionData("867C7151", _piAddress, _activityInstanceId); }
    }; };
    export const decode = (client: Provider, data: Uint8Array | undefined, topics: Uint8Array[] = []) => { const codec = client.contractCodec(abi); return {
        complete: (): void => { return; }
    }; };
}