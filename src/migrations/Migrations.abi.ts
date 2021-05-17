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
export module Migrations {
    export const contactName = "Migrations";
    export const abi = '[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"eventId","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"index","type":"uint256"},{"indexed":false,"internalType":"string","name":"name","type":"string"},{"indexed":false,"internalType":"int256","name":"runOnTimestamp","type":"int256"},{"indexed":false,"internalType":"uint256","name":"height","type":"uint256"},{"indexed":false,"internalType":"address","name":"owner","type":"address"}],"name":"LogMigration","type":"event"},{"constant":true,"inputs":[],"name":"head","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"migrate","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"migrationAt","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"string","name":"name","type":"string"}],"name":"migrationByName","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"numberOfMigrations","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"}]';
    export const bytecode = '608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550611656806100606000396000f3fe608060405234801561001057600080fd5b50600436106100625760003560e01c80633fff6227146100675780635ab48c65146101155780635f659f3d146101985780638da5cb5b146102915780638f7dcfa3146102db578063be123fdb14610365575b600080fd5b6100936004803603602081101561007d57600080fd5b8101908080359060200190929190505050610383565b6040518083815260200180602001828103825283818151815260200191508051906020019080838360005b838110156100d95780820151818401526020810190506100be565b50505050905090810190601f1680156101065780820380516001836020036101000a031916815260200191505b50935050505060405180910390f35b6101966004803603604081101561012b57600080fd5b810190808035906020019064010000000081111561014857600080fd5b82018360208201111561015a57600080fd5b8035906020019184600183028401116401000000008311171561017c57600080fd5b90919293919293908035906020019092919050505061082e565b005b61020f600480360360208110156101ae57600080fd5b81019080803590602001906401000000008111156101cb57600080fd5b8201836020820111156101dd57600080fd5b803590602001918460018302840111640100000000831117156101ff57600080fd5b9091929391929390505050610fe8565b6040518083815260200180602001828103825283818151815260200191508051906020019080838360005b8381101561025557808201518184015260208101905061023a565b50505050905090810190601f1680156102825780820380516001836020036101000a031916815260200191505b50935050505060405180910390f35b610299611101565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6102e3611126565b6040518083815260200180602001828103825283818151815260200191508051906020019080838360005b8381101561032957808201518184015260208101905061030e565b50505050905090810190601f1680156103565780820380516001836020036101000a031916815260200191505b50935050505060405180910390f35b61036d611263565b6040518082815260200191505060405180910390f35b60006060600180549050831115610725576106846040518060400160405280600f81526020017f546865726520617265206f6e6c7920000000000000000000000000000000000081525060018054905073__$1483b111869e15ef6c698c5f10f0d4a934$__636900a3ae90916040518263ffffffff1660e01b81526004018082815260200191505060006040518083038186803b15801561042357600080fd5b505af4158015610437573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f82011682018060405250602081101561046157600080fd5b810190808051604051939291908464010000000082111561048157600080fd5b8382019150602082018581111561049757600080fd5b82518660018202830111640100000000821117156104b457600080fd5b8083526020830192505050908051906020019080838360005b838110156104e85780820151818401526020810190506104cd565b50505050905090810190601f1680156105155780820380516001836020036101000a031916815260200191505b506040525050506040518060600160405280603081526020016115ca603091398673__$1483b111869e15ef6c698c5f10f0d4a934$__636900a3ae90916040518263ffffffff1660e01b81526004018082815260200191505060006040518083038186803b15801561058657600080fd5b505af415801561059a573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f8201168201806040525060208110156105c457600080fd5b81019080805160405193929190846401000000008211156105e457600080fd5b838201915060208201858111156105fa57600080fd5b825186600182028301116401000000008211171561061757600080fd5b8083526020830192505050908051906020019080838360005b8381101561064b578082015181840152602081019050610630565b50505050905090810190601f1680156106785780820380516001836020036101000a031916815260200191505b50604052505050611270565b6040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825283818151815260200191508051906020019080838360005b838110156106ea5780820151818401526020810190506106cf565b50505050905090810190601f1680156107175780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b61072d6114fc565b60018085038154811061073c57fe5b906000526020600020906004020160405180608001604052908160008201548152602001600182018054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156107f85780601f106107cd576101008083540402835291602001916107f8565b820191906000526020600020905b8154815290600101906020018083116107db57829003601f168201915b50505050508152602001600282015481526020016003820154815250509050806000015181602001518090509250925050915091565b6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161415610fe357600060018080549050019050818114610c2257610b816040518060400160405280601f81526020017f417474656d7074696e6720746f20616464206d6967726174696f6e20617420008152508373__$1483b111869e15ef6c698c5f10f0d4a934$__636900a3ae90916040518263ffffffff1660e01b81526004018082815260200191505060006040518083038186803b15801561092057600080fd5b505af4158015610934573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f82011682018060405250602081101561095e57600080fd5b810190808051604051939291908464010000000082111561097e57600080fd5b8382019150602082018581111561099457600080fd5b82518660018202830111640100000000821117156109b157600080fd5b8083526020830192505050908051906020019080838360005b838110156109e55780820151818401526020810190506109ca565b50505050905090810190601f168015610a125780820380516001836020036101000a031916815260200191505b506040525050506040518060600160405280602881526020016115fa602891398473__$1483b111869e15ef6c698c5f10f0d4a934$__636900a3ae90916040518263ffffffff1660e01b81526004018082815260200191505060006040518083038186803b158015610a8357600080fd5b505af4158015610a97573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f820116820180604052506020811015610ac157600080fd5b8101908080516040519392919084640100000000821115610ae157600080fd5b83820191506020820185811115610af757600080fd5b8251866001820283011164010000000082111715610b1457600080fd5b8083526020830192505050908051906020019080838360005b83811015610b48578082015181840152602081019050610b2d565b50505050905090810190601f168015610b755780820380516001836020036101000a031916815260200191505b50604052505050611270565b6040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825283818151815260200191508051906020019080838360005b83811015610be7578082015181840152602081019050610bcc565b50505050905090810190601f168015610c145780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b60006002858560405180838380828437808301925050509250505090815260200160405180910390206000015414610dae57610d0d6040518060400160405280600b81526020017f4d6967726174696f6e202700000000000000000000000000000000000000000081525085858080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050506040518060400160405280601081526020017f2720616c726561647920657869737473000000000000000000000000000000008152506113e0565b6040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825283818151815260200191508051906020019080838360005b83811015610d73578082015181840152602081019050610d58565b50505050905090810190601f168015610da05780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b610db66114fc565b604051806080016040528084815260200186868080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f82011690508083019250505050505050815260200142815260200143815250905060018190806001815401808255809150509060018203906000526020600020906004020160009091929091909150600082015181600001556020820151816001019080519060200190610e71929190611524565b50604082015181600201556060820151816003015550505080600286866040518083838082843780830192505050925050509081526020016040518091039020600082015181600001556020820151816001019080519060200190610ed7929190611524565b5060408201518160020155606082015181600301559050507f414e3a2f2f6d6967726174696f6e7300000000000000000000000000000000007f45bddb0c8effbe7cfeac9f965fe98c6bac60eb77b936b1d79faf92fa43ccfa9a84878742436000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1660405180878152602001806020018581526020018481526020018373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018281038252878782818152602001925080828437600081840152601f19601f82011690508083019250505097505050505050505060405180910390a250505b505050565b60006060610ff46114fc565b60028585604051808383808284378083019250505092505050908152602001604051809103902060405180608001604052908160008201548152602001600182018054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156110c95780601f1061109e576101008083540402835291602001916110c9565b820191906000526020600020905b8154815290600101906020018083116110ac57829003601f168201915b505050505081526020016002820154815260200160038201548152505090508060000151816020015180905092509250509250929050565b6000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6000606060006001805490501115611245576111406114fc565b6001808080549050038154811061115357fe5b906000526020600020906004020160405180608001604052908160008201548152602001600182018054600181600116156101000203166002900480601f01602080910402602001604051908101604052809291908181526020018280546001816001161561010002031660029004801561120f5780601f106111e45761010080835404028352916020019161120f565b820191906000526020600020905b8154815290600101906020018083116111f257829003601f168201915b5050505050815260200160028201548152602001600382015481525050905080600001518160200151809050925092505061125f565b600080905060405180602001604052806000815250915091505b9091565b6000600180549050905090565b6060848484846040516020018085805190602001908083835b602083106112ac5780518252602082019150602081019050602083039250611289565b6001836020036101000a03801982511681845116808217855250505050505090500184805190602001908083835b602083106112fd57805182526020820191506020810190506020830392506112da565b6001836020036101000a03801982511681845116808217855250505050505090500183805190602001908083835b6020831061134e578051825260208201915060208101905060208303925061132b565b6001836020036101000a03801982511681845116808217855250505050505090500182805190602001908083835b6020831061139f578051825260208201915060208101905060208303925061137c565b6001836020036101000a0380198251168184511680821785525050505050509050019450505050506040516020818303038152906040529050949350505050565b60608383836040516020018084805190602001908083835b6020831061141b57805182526020820191506020810190506020830392506113f8565b6001836020036101000a03801982511681845116808217855250505050505090500183805190602001908083835b6020831061146c5780518252602082019150602081019050602083039250611449565b6001836020036101000a03801982511681845116808217855250505050505090500182805190602001908083835b602083106114bd578051825260208201915060208101905060208303925061149a565b6001836020036101000a038019825116818451168082178552505050505050905001935050505060405160208183030381529060405290509392505050565b6040518060800160405280600081526020016060815260200160008152602001600081525090565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061156557805160ff1916838001178555611593565b82800160010185558215611593579182015b82811115611592578251825591602001919060010190611577565b5b5090506115a091906115a4565b5090565b6115c691905b808211156115c25760008160009055506001016115aa565b5090565b9056fe206d6967726174696f6e7320736f2063616e6e6f742072657475726e206d6967726174696f6e20617420696e6465782020627574206e657874206d6967726174696f6e732073686f756c6420626520617420696e64657820a265627a7a72315820546365653e0f6eb8b4f57ceecc20046825c55f3f05afa876b5c9898bd64653b064736f6c63430005110032';
    export function deploy(client: Provider, commons_utils_Strings_sol_Strings: string): Promise<string> {
        const codec = client.contractCodec(abi);
        let linkedBytecode = bytecode;
        linkedBytecode = linker(linkedBytecode, "$1483b111869e15ef6c698c5f10f0d4a934$", commons_utils_Strings_sol_Strings);
        const data = Buffer.concat([Buffer.from(linkedBytecode, "hex"), codec.encodeDeploy()]);
        const payload = client.payload(data);
        return client.deploy(payload);
    }
    export async function deployContract(client: Provider, commons_utils_Strings_sol_Strings: string): Promise<Contract> { const address = await deploy(client, commons_utils_Strings_sol_Strings); return contract(client, address); }
    type EventRegistry = typeof events;
    export type EventName = keyof EventRegistry;
    export type TaggedPayload<T extends EventName> = ReturnType<EventRegistry[T]["tagged"]> & {
        event: Event;
    };
    export type SolidityEvent<T extends EventName> = TaggedPayload<T>["payload"];
    export type TypedListener<T extends EventName> = (callback: (err?: Error, event?: TaggedPayload<T>) => void, start?: "first" | "latest" | "stream" | number, end?: "first" | "latest" | "stream" | number) => EventStream;
    const events = { LogMigration: { signature: "45BDDB0C8EFFBE7CFEAC9F965FE98C6BAC60EB77B936B1D79FAF92FA43CCFA9A", tagged: (eventId: Buffer, index: number, name: string, runOnTimestamp: number, height: number, owner: string) => ({ name: "LogMigration", payload: { eventId: eventId, index: index, name: name, runOnTimestamp: runOnTimestamp, height: height, owner: owner } as const } as const) } as const } as const;
    export type Contract = ReturnType<typeof contract>;
    export const contract = (client: Provider, address: string) => ({ address, functions: { head(call = defaultCall): Promise<[
                number,
                string
            ]> {
                const data = encode(client).head();
                return call<[
                    number,
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).head();
                });
            }, migrate(name: string, index: number, call = defaultCall): Promise<void> {
                const data = encode(client).migrate(name, index);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).migrate();
                });
            }, migrationAt(index: number, call = defaultCall): Promise<[
                number,
                string
            ]> {
                const data = encode(client).migrationAt(index);
                return call<[
                    number,
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).migrationAt();
                });
            }, migrationByName(name: string, call = defaultCall): Promise<[
                number,
                string
            ]> {
                const data = encode(client).migrationByName(name);
                return call<[
                    number,
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).migrationByName();
                });
            }, numberOfMigrations(call = defaultCall): Promise<[
                number
            ]> {
                const data = encode(client).numberOfMigrations();
                return call<[
                    number
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).numberOfMigrations();
                });
            }, owner(call = defaultCall): Promise<[
                string
            ]> {
                const data = encode(client).owner();
                return call<[
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).owner();
                });
            } } as const, listeners: { LogMigration(callback: (err?: Error, event?: {
                eventId: Buffer;
                index: number;
                name: string;
                runOnTimestamp: number;
                height: number;
                owner: string;
            }) => Signal | void, start?: "first" | "latest" | "stream" | number, end?: "first" | "latest" | "stream" | number): EventStream { return client.listen(["45BDDB0C8EFFBE7CFEAC9F965FE98C6BAC60EB77B936B1D79FAF92FA43CCFA9A"], address, (err?: Error, event?: Event) => { if (err)
                return callback(err); return callback(undefined, decode(client, event?.getLog()?.getData_asU8(), event?.getLog()?.getTopicsList_asU8()).LogMigration()); }, start, end); } } as const, listenerFor: <T extends EventName>(eventNames: T[]): TypedListener<T> => listenerFor(client, address, events, decode, eventNames) as unknown as TypedListener<T>, listener: listenerFor(client, address, events, decode, Object.keys(events) as EventName[]) as TypedListener<EventName> } as const);
    export const encode = (client: Provider) => { const codec = client.contractCodec(abi); return {
        head: () => { return codec.encodeFunctionData("8F7DCFA3"); },
        migrate: (name: string, index: number) => { return codec.encodeFunctionData("5AB48C65", name, index); },
        migrationAt: (index: number) => { return codec.encodeFunctionData("3FFF6227", index); },
        migrationByName: (name: string) => { return codec.encodeFunctionData("5F659F3D", name); },
        numberOfMigrations: () => { return codec.encodeFunctionData("BE123FDB"); },
        owner: () => { return codec.encodeFunctionData("8DA5CB5B"); }
    }; };
    export const decode = (client: Provider, data: Uint8Array | undefined, topics: Uint8Array[] = []) => { const codec = client.contractCodec(abi); return {
        LogMigration: (): {
            eventId: Buffer;
            index: number;
            name: string;
            runOnTimestamp: number;
            height: number;
            owner: string;
        } => {
            const [eventId, index, name, runOnTimestamp, height, owner] = codec.decodeEventLog ("45BDDB0C8EFFBE7CFEAC9F965FE98C6BAC60EB77B936B1D79FAF92FA43CCFA9A", data, topics);
            return { eventId: eventId, index: index, name: name, runOnTimestamp: runOnTimestamp, height: height, owner: owner };
        },
        head: (): [
            number,
            string
        ] => { return codec.decodeFunctionResult ("8F7DCFA3", data); },
        migrate: (): void => { return; },
        migrationAt: (): [
            number,
            string
        ] => { return codec.decodeFunctionResult ("3FFF6227", data); },
        migrationByName: (): [
            number,
            string
        ] => { return codec.decodeFunctionResult ("5F659F3D", data); },
        numberOfMigrations: (): [
            number
        ] => { return codec.decodeFunctionResult ("BE123FDB", data); },
        owner: (): [
            string
        ] => { return codec.decodeFunctionResult ("8DA5CB5B", data); }
    }; };
}