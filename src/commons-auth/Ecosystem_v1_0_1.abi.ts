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
export module Ecosystem_v1_0_1 {
    export const contactName = "Ecosystem_v1_0_1";
    export const abi = '[{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":false,"internalType":"address","name":"newOwner","type":"address"}],"name":"LogOwnerChanged","type":"event"},{"constant":true,"inputs":[],"name":"ERC165_ID_VERSIONED_ARTIFACT","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_address","type":"address"}],"name":"addExternalAddress","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"_id","type":"bytes32"},{"internalType":"address","name":"_userAccount","type":"address"}],"name":"addUserAccount","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_other","type":"address"}],"name":"compareArtifactVersion","outputs":[{"internalType":"int256","name":"result","type":"int256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"uint8[3]","name":"_version","type":"uint8[3]"}],"name":"compareArtifactVersion","outputs":[{"internalType":"int256","name":"result","type":"int256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getArtifactVersion","outputs":[{"internalType":"uint8[3]","name":"","type":"uint8[3]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getArtifactVersionMajor","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getArtifactVersionMinor","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getArtifactVersionPatch","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"bytes32","name":"_id","type":"bytes32"}],"name":"getUserAccount","outputs":[{"internalType":"address","name":"_account","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"initialize","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_address","type":"address"}],"name":"isKnownExternalAddress","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_userAccount","type":"address"},{"internalType":"bytes32","name":"_migrateFromId","type":"bytes32"},{"internalType":"bytes32","name":"_migrateToId","type":"bytes32"}],"name":"migrateUserAccount","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_address","type":"address"}],"name":"removeExternalAddress","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
    type EventRegistry = typeof events;
    export type EventName = keyof EventRegistry;
    export type TaggedPayload<T extends EventName> = ReturnType<EventRegistry[T]["tagged"]> & {
        event: Event;
    };
    export type SolidityEvent<T extends EventName> = TaggedPayload<T>["payload"];
    export type TypedListener<T extends EventName> = (callback: (err?: Error, event?: TaggedPayload<T>) => void, start?: "first" | "latest" | "stream" | number, end?: "first" | "latest" | "stream" | number) => EventStream;
    const events = { LogOwnerChanged: { signature: "FCF23A92150D56E85E3A3D33B357493246E55783095EB6A733EB8439FFC752C8", tagged: (previousOwner: string, newOwner: string) => ({ name: "LogOwnerChanged", payload: { previousOwner: previousOwner, newOwner: newOwner } as const } as const) } as const } as const;
    export type Contract = ReturnType<typeof contract>;
    export const contract = (client: Provider, address: string) => ({ address, functions: { ERC165_ID_VERSIONED_ARTIFACT(call = defaultCall): Promise<[
                Buffer
            ]> {
                const data = encode(client).ERC165_ID_VERSIONED_ARTIFACT();
                return call<[
                    Buffer
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).ERC165_ID_VERSIONED_ARTIFACT();
                });
            }, addExternalAddress(_address: string, call = defaultCall): Promise<void> {
                const data = encode(client).addExternalAddress(_address);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).addExternalAddress();
                });
            }, addUserAccount(_id: Buffer, _userAccount: string, call = defaultCall): Promise<void> {
                const data = encode(client).addUserAccount(_id, _userAccount);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).addUserAccount();
                });
            }, compareArtifactVersion(_other: string, call = defaultCall): Promise<{
                result: number;
            }> {
                const data = encode(client).compareArtifactVersion[0](_other);
                return call<{
                    result: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).compareArtifactVersion[0]();
                });
            }, compareArtifactVersion_1(_version: [
                number,
                number,
                number
            ], call = defaultCall): Promise<{
                result: number;
            }> {
                const data = encode(client).compareArtifactVersion[1](_version);
                return call<{
                    result: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).compareArtifactVersion[1]();
                });
            }, getArtifactVersion(call = defaultCall): Promise<[
                [
                    number,
                    number,
                    number
                ]
            ]> {
                const data = encode(client).getArtifactVersion();
                return call<[
                    [
                        number,
                        number,
                        number
                    ]
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getArtifactVersion();
                });
            }, getArtifactVersionMajor(call = defaultCall): Promise<[
                number
            ]> {
                const data = encode(client).getArtifactVersionMajor();
                return call<[
                    number
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getArtifactVersionMajor();
                });
            }, getArtifactVersionMinor(call = defaultCall): Promise<[
                number
            ]> {
                const data = encode(client).getArtifactVersionMinor();
                return call<[
                    number
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getArtifactVersionMinor();
                });
            }, getArtifactVersionPatch(call = defaultCall): Promise<[
                number
            ]> {
                const data = encode(client).getArtifactVersionPatch();
                return call<[
                    number
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getArtifactVersionPatch();
                });
            }, getOwner(call = defaultCall): Promise<[
                string
            ]> {
                const data = encode(client).getOwner();
                return call<[
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getOwner();
                });
            }, getUserAccount(_id: Buffer, call = defaultCall): Promise<{
                _account: string;
            }> {
                const data = encode(client).getUserAccount(_id);
                return call<{
                    _account: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getUserAccount();
                });
            }, initialize(call = defaultCall): Promise<void> {
                const data = encode(client).initialize();
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).initialize();
                });
            }, isKnownExternalAddress(_address: string, call = defaultCall): Promise<[
                boolean
            ]> {
                const data = encode(client).isKnownExternalAddress(_address);
                return call<[
                    boolean
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).isKnownExternalAddress();
                });
            }, migrateUserAccount(_userAccount: string, _migrateFromId: Buffer, _migrateToId: Buffer, call = defaultCall): Promise<void> {
                const data = encode(client).migrateUserAccount(_userAccount, _migrateFromId, _migrateToId);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).migrateUserAccount();
                });
            }, removeExternalAddress(_address: string, call = defaultCall): Promise<void> {
                const data = encode(client).removeExternalAddress(_address);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).removeExternalAddress();
                });
            }, transferOwnership(_newOwner: string, call = defaultCall): Promise<void> {
                const data = encode(client).transferOwnership(_newOwner);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).transferOwnership();
                });
            } } as const, listeners: { LogOwnerChanged(callback: (err?: Error, event?: {
                previousOwner: string;
                newOwner: string;
            }) => Signal | void, start?: "first" | "latest" | "stream" | number, end?: "first" | "latest" | "stream" | number): EventStream { return client.listen(["FCF23A92150D56E85E3A3D33B357493246E55783095EB6A733EB8439FFC752C8"], address, (err?: Error, event?: Event) => { if (err)
                return callback(err); return callback(undefined, decode(client, event?.getLog()?.getData_asU8(), event?.getLog()?.getTopicsList_asU8()).LogOwnerChanged()); }, start, end); } } as const, listenerFor: <T extends EventName>(eventNames: T[]): TypedListener<T> => listenerFor(client, address, events, decode, eventNames) as unknown as TypedListener<T>, listener: listenerFor(client, address, events, decode, Object.keys(events) as EventName[]) as TypedListener<EventName> } as const);
    export const encode = (client: Provider) => { const codec = client.contractCodec(abi); return {
        ERC165_ID_VERSIONED_ARTIFACT: () => { return codec.encodeFunctionData("E10533C6"); },
        addExternalAddress: (_address: string) => { return codec.encodeFunctionData("697FD9E9", _address); },
        addUserAccount: (_id: Buffer, _userAccount: string) => { return codec.encodeFunctionData("DDEB1CFC", _id, _userAccount); },
        compareArtifactVersion: [(_other: string) => { return codec.encodeFunctionData("5C030138", _other); }, (_version: [
                number,
                number,
                number
            ]) => { return codec.encodeFunctionData("78BC0B0D", _version); }] as const,
        getArtifactVersion: () => { return codec.encodeFunctionData("756B2E6C"); },
        getArtifactVersionMajor: () => { return codec.encodeFunctionData("57E0EBCA"); },
        getArtifactVersionMinor: () => { return codec.encodeFunctionData("7589ADB7"); },
        getArtifactVersionPatch: () => { return codec.encodeFunctionData("F085F6DD"); },
        getOwner: () => { return codec.encodeFunctionData("893D20E8"); },
        getUserAccount: (_id: Buffer) => { return codec.encodeFunctionData("7D19EC9D", _id); },
        initialize: () => { return codec.encodeFunctionData("8129FC1C"); },
        isKnownExternalAddress: (_address: string) => { return codec.encodeFunctionData("9B9016AE", _address); },
        migrateUserAccount: (_userAccount: string, _migrateFromId: Buffer, _migrateToId: Buffer) => { return codec.encodeFunctionData("49C77F8C", _userAccount, _migrateFromId, _migrateToId); },
        removeExternalAddress: (_address: string) => { return codec.encodeFunctionData("30D8B8C1", _address); },
        transferOwnership: (_newOwner: string) => { return codec.encodeFunctionData("F2FDE38B", _newOwner); }
    }; };
    export const decode = (client: Provider, data: Uint8Array | undefined, topics: Uint8Array[] = []) => { const codec = client.contractCodec(abi); return {
        LogOwnerChanged: (): {
            previousOwner: string;
            newOwner: string;
        } => {
            const [previousOwner, newOwner] = codec.decodeEventLog ("FCF23A92150D56E85E3A3D33B357493246E55783095EB6A733EB8439FFC752C8", data, topics);
            return { previousOwner: previousOwner, newOwner: newOwner };
        },
        ERC165_ID_VERSIONED_ARTIFACT: (): [
            Buffer
        ] => { return codec.decodeFunctionResult ("E10533C6", data); },
        addExternalAddress: (): void => { return; },
        addUserAccount: (): void => { return; },
        compareArtifactVersion: [(): {
                result: number;
            } => {
                const [result] = codec.decodeFunctionResult ("5C030138", data);
                return { result: result };
            }, (): {
                result: number;
            } => {
                const [result] = codec.decodeFunctionResult ("78BC0B0D", data);
                return { result: result };
            }] as const,
        getArtifactVersion: (): [
            [
                number,
                number,
                number
            ]
        ] => { return codec.decodeFunctionResult ("756B2E6C", data); },
        getArtifactVersionMajor: (): [
            number
        ] => { return codec.decodeFunctionResult ("57E0EBCA", data); },
        getArtifactVersionMinor: (): [
            number
        ] => { return codec.decodeFunctionResult ("7589ADB7", data); },
        getArtifactVersionPatch: (): [
            number
        ] => { return codec.decodeFunctionResult ("F085F6DD", data); },
        getOwner: (): [
            string
        ] => { return codec.decodeFunctionResult ("893D20E8", data); },
        getUserAccount: (): {
            _account: string;
        } => {
            const [_account] = codec.decodeFunctionResult ("7D19EC9D", data);
            return { _account: _account };
        },
        initialize: (): void => { return; },
        isKnownExternalAddress: (): [
            boolean
        ] => { return codec.decodeFunctionResult ("9B9016AE", data); },
        migrateUserAccount: (): void => { return; },
        removeExternalAddress: (): void => { return; },
        transferOwnership: (): void => { return; }
    }; };
}