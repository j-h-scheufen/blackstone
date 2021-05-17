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
export module EcosystemRegistryDb {
    export const contactName = "EcosystemRegistryDb";
    export const abi = '[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":false,"internalType":"address","name":"newOwner","type":"address"}],"name":"LogSystemOwnerChanged","type":"event"},{"constant":false,"inputs":[{"internalType":"string","name":"_name","type":"string"},{"internalType":"address","name":"_address","type":"address"}],"name":"addEcosystem","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"string","name":"_name","type":"string"}],"name":"ecosystemExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"string","name":"_name","type":"string"}],"name":"getEcosystemDetails","outputs":[{"internalType":"address","name":"ecosystemAddress","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"uint256","name":"_index","type":"uint256"}],"name":"getEcosystemKeyAtIndex","outputs":[{"internalType":"string","name":"key","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getNumberOfEcosystems","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getSystemOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"string","name":"_name","type":"string"}],"name":"removeEcosystem","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_newOwner","type":"address"}],"name":"transferSystemOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
    export const bytecode = '608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506110cb806100606000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c8063473c00301161005b578063473c0030146101f957806363293ffd146102b25780637f692a2a1461034b57806395e5b3d51461039557610088565b80630a452ad61461008d578063307b0a4f146100d15780634147a676146100ef578063437474c214610168575b600080fd5b6100cf600480360360208110156100a357600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919050505061043c565b005b6100d9610839565b6040518082815260200191505060405180910390f35b6101666004803603602081101561010557600080fd5b810190808035906020019064010000000081111561012257600080fd5b82018360208201111561013457600080fd5b8035906020019184600183028401116401000000008311171561015657600080fd5b9091929391929390505050610848565b005b6101df6004803603602081101561017e57600080fd5b810190808035906020019064010000000081111561019b57600080fd5b8201836020820111156101ad57600080fd5b803590602001918460018302840111640100000000831117156101cf57600080fd5b9091929391929390505050610a75565b604051808215151515815260200191505060405180910390f35b6102706004803603602081101561020f57600080fd5b810190808035906020019064010000000081111561022c57600080fd5b82018360208201111561023e57600080fd5b8035906020019184600183028401116401000000008311171561026057600080fd5b9091929391929390505050610b40565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b610349600480360360408110156102c857600080fd5b81019080803590602001906401000000008111156102e557600080fd5b8201836020820111156102f757600080fd5b8035906020019184600183028401116401000000008311171561031957600080fd5b9091929391929390803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610b98565b005b610353610dfa565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6103c1600480360360208110156103ab57600080fd5b8101908080359060200190929190505050610e23565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156104015780820151818401526020810190506103e6565b50505050905090810190601f16801561042e5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b73__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614156104af610f8d565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b838110156105105780820151818401526020810190506104f5565b50505050905090810190601f16801561053d5780820380516001836020036101000a031916815260200191505b5084810383526021815260200180611076602191396040018481038252602681526020018061102b602691396040019550505050505060006040518083038186803b15801561058b57600080fd5b505af415801561059f573d6000803e3d6000fd5b5050505073__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff16146105f5610fca565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b8381101561065657808201518184015260208101905061063b565b50505050905090810190601f1680156106835780820380516001836020036101000a031916815260200191505b50848103835260238152602001806110086023913960400184810382526025815260200180611051602591396040019550505050505060006040518083038186803b1580156106d157600080fd5b505af41580156106e5573d6000803e3d6000fd5b505050508073ffffffffffffffffffffffffffffffffffffffff166000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1614610836577f0814a6975d95b7ef86d699e601b879308be10e8f2c4c77a940021f3d61b09eaf6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1682604051808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019250505060405180910390a1806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b50565b60006001800180549050905090565b73__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614156108bb610f8d565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b8381101561091c578082015181840152602081019050610901565b50505050905090810190601f1680156109495780820380516001836020036101000a031916815260200191505b5084810383526021815260200180611076602191396040018481038252602681526020018061102b602691396040019550505050505060006040518083038186803b15801561099757600080fd5b505af41580156109ab573d6000803e3d6000fd5b50505050600173__$5e3d4bda46c81e962f48c99e99f980d175$__634d6c2672909184846040518463ffffffff1660e01b815260040180848152602001806020018281038252848482818152602001925080828437600081840152601f19601f82011690508083019250505094505050505060206040518083038186803b158015610a3557600080fd5b505af4158015610a49573d6000803e3d6000fd5b505050506040513d6020811015610a5f57600080fd5b8101908080519060200190929190505050505050565b6000600173__$5e3d4bda46c81e962f48c99e99f980d175$__63b950ac88909185856040518463ffffffff1660e01b815260040180848152602001806020018281038252848482818152602001925080828437600081840152601f19601f82011690508083019250505094505050505060206040518083038186803b158015610afd57600080fd5b505af4158015610b11573d6000803e3d6000fd5b505050506040513d6020811015610b2757600080fd5b8101908080519060200190929190505050905092915050565b600060016000018383604051808383808284378083019250505092505050908152602001604051809103902060010160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905092915050565b73__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161415610c0b610f8d565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b83811015610c6c578082015181840152602081019050610c51565b50505050905090810190601f168015610c995780820380516001836020036101000a031916815260200191505b5084810383526021815260200180611076602191396040018481038252602681526020018061102b602691396040019550505050505060006040518083038186803b158015610ce757600080fd5b505af4158015610cfb573d6000803e3d6000fd5b50505050600173__$5e3d4bda46c81e962f48c99e99f980d175$__63c9de9e8690918585856040518563ffffffff1660e01b815260040180858152602001806020018373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018281038252858582818152602001925080828437600081840152601f19601f8201169050808301925050509550505050505060206040518083038186803b158015610db957600080fd5b505af4158015610dcd573d6000803e3d6000fd5b505050506040513d6020811015610de357600080fd5b810190808051906020019092919050505050505050565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b6060600173__$5e3d4bda46c81e962f48c99e99f980d175$__6391a497b69091846040518363ffffffff1660e01b8152600401808381526020018281526020019250505060006040518083038186803b158015610e7f57600080fd5b505af4158015610e93573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f820116820180604052506040811015610ebd57600080fd5b810190808051906020019092919080516040519392919084640100000000821115610ee757600080fd5b83820191506020820185811115610efd57600080fd5b8251866001820283011164010000000082111715610f1a57600080fd5b8083526020830192505050908051906020019080838360005b83811015610f4e578082015181840152602081019050610f33565b50505050905090810190601f168015610f7b5780820380516001836020036101000a031916815260200191505b50604052505050905080915050919050565b60606040518060400160405280600681526020017f4552523430330000000000000000000000000000000000000000000000000000815250905090565b60606040518060400160405280600681526020017f455252363131000000000000000000000000000000000000000000000000000081525090509056fe53797374656d4f776e65642e7472616e7366657253797374656d4f776e657273686970546865206d73672e73656e646572206973206e6f74207468652073797374656d206f776e6572546865206e65772073797374656d206f776e6572206d757374206e6f74206265204e554c4c53797374656d4f776e65642e7072655f6f6e6c79427953797374656d4f776e6572a265627a7a72315820a419d8df8e1d847155020cec4887467e0bfa124890e1d36d58c1fd51517b1c7d64736f6c63430005110032';
    export function deploy(client: Provider, commons_base_ErrorsLib_sol_ErrorsLib: string, commons_collections_MappingsLib_sol_MappingsLib: string): Promise<string> {
        const codec = client.contractCodec(abi);
        let linkedBytecode = bytecode;
        linkedBytecode = linker(linkedBytecode, "$ecfb6c4d3c3ceff197e19e585a0a53728c$", commons_base_ErrorsLib_sol_ErrorsLib);
        linkedBytecode = linker(linkedBytecode, "$5e3d4bda46c81e962f48c99e99f980d175$", commons_collections_MappingsLib_sol_MappingsLib);
        const data = Buffer.concat([Buffer.from(linkedBytecode, "hex"), codec.encodeDeploy()]);
        const payload = client.payload(data);
        return client.deploy(payload);
    }
    export async function deployContract(client: Provider, commons_base_ErrorsLib_sol_ErrorsLib: string, commons_collections_MappingsLib_sol_MappingsLib: string): Promise<Contract> { const address = await deploy(client, commons_base_ErrorsLib_sol_ErrorsLib, commons_collections_MappingsLib_sol_MappingsLib); return contract(client, address); }
    type EventRegistry = typeof events;
    export type EventName = keyof EventRegistry;
    export type TaggedPayload<T extends EventName> = ReturnType<EventRegistry[T]["tagged"]> & {
        event: Event;
    };
    export type SolidityEvent<T extends EventName> = TaggedPayload<T>["payload"];
    export type TypedListener<T extends EventName> = (callback: (err?: Error, event?: TaggedPayload<T>) => void, start?: "first" | "latest" | "stream" | number, end?: "first" | "latest" | "stream" | number) => EventStream;
    const events = { LogSystemOwnerChanged: { signature: "0814A6975D95B7EF86D699E601B879308BE10E8F2C4C77A940021F3D61B09EAF", tagged: (previousOwner: string, newOwner: string) => ({ name: "LogSystemOwnerChanged", payload: { previousOwner: previousOwner, newOwner: newOwner } as const } as const) } as const } as const;
    export type Contract = ReturnType<typeof contract>;
    export const contract = (client: Provider, address: string) => ({ address, functions: { addEcosystem(_name: string, _address: string, call = defaultCall): Promise<void> {
                const data = encode(client).addEcosystem(_name, _address);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).addEcosystem();
                });
            }, ecosystemExists(_name: string, call = defaultCall): Promise<[
                boolean
            ]> {
                const data = encode(client).ecosystemExists(_name);
                return call<[
                    boolean
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).ecosystemExists();
                });
            }, getEcosystemDetails(_name: string, call = defaultCall): Promise<{
                ecosystemAddress: string;
            }> {
                const data = encode(client).getEcosystemDetails(_name);
                return call<{
                    ecosystemAddress: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getEcosystemDetails();
                });
            }, getEcosystemKeyAtIndex(_index: number, call = defaultCall): Promise<{
                key: string;
            }> {
                const data = encode(client).getEcosystemKeyAtIndex(_index);
                return call<{
                    key: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getEcosystemKeyAtIndex();
                });
            }, getNumberOfEcosystems(call = defaultCall): Promise<[
                number
            ]> {
                const data = encode(client).getNumberOfEcosystems();
                return call<[
                    number
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getNumberOfEcosystems();
                });
            }, getSystemOwner(call = defaultCall): Promise<[
                string
            ]> {
                const data = encode(client).getSystemOwner();
                return call<[
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getSystemOwner();
                });
            }, removeEcosystem(_name: string, call = defaultCall): Promise<void> {
                const data = encode(client).removeEcosystem(_name);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).removeEcosystem();
                });
            }, transferSystemOwnership(_newOwner: string, call = defaultCall): Promise<void> {
                const data = encode(client).transferSystemOwnership(_newOwner);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).transferSystemOwnership();
                });
            } } as const, listeners: { LogSystemOwnerChanged(callback: (err?: Error, event?: {
                previousOwner: string;
                newOwner: string;
            }) => Signal | void, start?: "first" | "latest" | "stream" | number, end?: "first" | "latest" | "stream" | number): EventStream { return client.listen(["0814A6975D95B7EF86D699E601B879308BE10E8F2C4C77A940021F3D61B09EAF"], address, (err?: Error, event?: Event) => { if (err)
                return callback(err); return callback(undefined, decode(client, event?.getLog()?.getData_asU8(), event?.getLog()?.getTopicsList_asU8()).LogSystemOwnerChanged()); }, start, end); } } as const, listenerFor: <T extends EventName>(eventNames: T[]): TypedListener<T> => listenerFor(client, address, events, decode, eventNames) as unknown as TypedListener<T>, listener: listenerFor(client, address, events, decode, Object.keys(events) as EventName[]) as TypedListener<EventName> } as const);
    export const encode = (client: Provider) => { const codec = client.contractCodec(abi); return {
        addEcosystem: (_name: string, _address: string) => { return codec.encodeFunctionData("63293FFD", _name, _address); },
        ecosystemExists: (_name: string) => { return codec.encodeFunctionData("437474C2", _name); },
        getEcosystemDetails: (_name: string) => { return codec.encodeFunctionData("473C0030", _name); },
        getEcosystemKeyAtIndex: (_index: number) => { return codec.encodeFunctionData("95E5B3D5", _index); },
        getNumberOfEcosystems: () => { return codec.encodeFunctionData("307B0A4F"); },
        getSystemOwner: () => { return codec.encodeFunctionData("7F692A2A"); },
        removeEcosystem: (_name: string) => { return codec.encodeFunctionData("4147A676", _name); },
        transferSystemOwnership: (_newOwner: string) => { return codec.encodeFunctionData("0A452AD6", _newOwner); }
    }; };
    export const decode = (client: Provider, data: Uint8Array | undefined, topics: Uint8Array[] = []) => { const codec = client.contractCodec(abi); return {
        LogSystemOwnerChanged: (): {
            previousOwner: string;
            newOwner: string;
        } => {
            const [previousOwner, newOwner] = codec.decodeEventLog ("0814A6975D95B7EF86D699E601B879308BE10E8F2C4C77A940021F3D61B09EAF", data, topics);
            return { previousOwner: previousOwner, newOwner: newOwner };
        },
        addEcosystem: (): void => { return; },
        ecosystemExists: (): [
            boolean
        ] => { return codec.decodeFunctionResult ("437474C2", data); },
        getEcosystemDetails: (): {
            ecosystemAddress: string;
        } => {
            const [ecosystemAddress] = codec.decodeFunctionResult ("473C0030", data);
            return { ecosystemAddress: ecosystemAddress };
        },
        getEcosystemKeyAtIndex: (): {
            key: string;
        } => {
            const [key] = codec.decodeFunctionResult ("95E5B3D5", data);
            return { key: key };
        },
        getNumberOfEcosystems: (): [
            number
        ] => { return codec.decodeFunctionResult ("307B0A4F", data); },
        getSystemOwner: (): [
            string
        ] => { return codec.decodeFunctionResult ("7F692A2A", data); },
        removeEcosystem: (): void => { return; },
        transferSystemOwnership: (): void => { return; }
    }; };
}