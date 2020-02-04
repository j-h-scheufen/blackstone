import { Readable } from "stream";
interface Provider<Tx> {
    deploy(msg: Tx, callback: (err: Error, addr: Uint8Array) => void): void;
    call(msg: Tx, callback: (err: Error, exec: Uint8Array) => void): void;
    listen(signature: string, address: string, callback: (err: Error, event: any) => void): Readable;
    payload(data: string, address?: string): Tx;
    encode(name: string, inputs: string[], ...args: any[]): string;
    decode(data: Uint8Array, outputs: string[]): any;
}
function Call<Tx, Output>(client: Provider<Tx>, addr: string, data: string, callback: (exec: Uint8Array) => Output): Promise<Output> {
    const payload = client.payload(data, addr);
    return new Promise((resolve, reject) => {
        client.call(payload, (err, exec) => { err ? reject(err) : resolve(callback(exec)); });
    });
}
function Replace(bytecode: string, name: string, address: string): string {
    address = address + Array(40 - address.length + 1).join("0");
    const truncated = name.slice(0, 36);
    const label = "__" + truncated + Array(37 - truncated.length).join("_") + "__";
    while (bytecode.indexOf(label) >= 0)
        bytecode = bytecode.replace(label, address);
    return bytecode;
}
export module WaitOracle {
    export function Deploy<Tx>(client: Provider<Tx>, commons_base_ErrorsLib_sol_ErrorsLib: string, _service: string): Promise<string> {
        let bytecode = "608060405234801561001057600080fd5b506040516109e13803806109e18339818101604052602081101561003357600080fd5b8101908080519060200190929190505050806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505061094d806100946000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c8063232ee5281461003b578063867c715114610069575b600080fd5b6100676004803603602081101561005157600080fd5b81019080803590602001909291905050506100e1565b005b6100df6004803603608081101561007f57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610504565b005b73__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef600073ffffffffffffffffffffffffffffffffffffffff166001600085815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1614610166610899565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b838110156101c75780820151818401526020810190506101ac565b50505050905090810190601f1680156101f45780820380516001836020036101000a031916815260200191505b50848103835260198152602001807f576169744f7261636c652e636f6d706c6574654f7261636c6500000000000000815250602001848103825260398152602001806108e0603991396040019550505050505060006040518083038186803b15801561025f57600080fd5b505af4158015610273573d6000803e3d6000fd5b5050505060006001600083815260200190815260200160002060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166368180951836000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff166040518363ffffffff1660e01b8152600401808381526020018273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200192505050602060405180830381600087803b15801561035457600080fd5b505af1158015610368573d6000803e3d6000fd5b505050506040513d602081101561037e57600080fd5b810190808051906020019092919050505090506103996108d6565b81141561046d576001600083815260200190815260200160002060006101000a81549073ffffffffffffffffffffffffffffffffffffffff0219169055817f414e3a2f2f6f7261636c65732f6d6f6e61782f74696d652f77616974000000007f371cce8fb8ca316c0ca808ace2db55d9f10e27f5ca379a2554c2951da8d81239306001604051808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001821515151581526020019250505060405180910390a3610500565b817f414e3a2f2f6f7261636c65732f6d6f6e61782f74696d652f77616974000000007f371cce8fb8ca316c0ca808ace2db55d9f10e27f5ca379a2554c2951da8d81239306000604051808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001821515151581526020019250505060405180910390a35b5050565b60608473ffffffffffffffffffffffffffffffffffffffff166326a3ba26857f4672657175656e637900000000000000000000000000000000000000000000006040518363ffffffff1660e01b81526004018083815260200182815260200192505050600060405180830381600087803b15801561058157600080fd5b505af1158015610595573d6000803e3d6000fd5b505050506040513d6000823e3d601f19601f8201168201806040525060208110156105bf57600080fd5b81019080805160405193929190846401000000008211156105df57600080fd5b838201915060208201858111156105f557600080fd5b825186600182028301116401000000008211171561061257600080fd5b8083526020830192505050908051906020019080838360005b8381101561064657808201518184015260208101905061062b565b50505050905090810190601f1680156106735780820380516001836020036101000a031916815260200191505b506040525050509050846001600086815260200190815260200160002060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550837f414e3a2f2f6f7261636c65732f6d6f6e61782f74696d652f77616974000000007f7fc3098e017dce628b9c4ebcc58a37ef3362f97e6f58715e7ab94393e10950af306000809054906101000a900473ffffffffffffffffffffffffffffffffffffffff16898742886000604051808873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018481526020018060200183151515158152602001828103825284818151815260200191508051906020019080838360005b83811015610852578082015181840152602081019050610837565b50505050905090810190601f16801561087f5780820380516001836020036101000a031916815260200191505b509850505050505050505060405180910390a35050505050565b60606040518060400160405280600681526020017f4552523432320000000000000000000000000000000000000000000000000000815250905090565b6000600190509056fe5468652070726f7669646564204163746976697479496e7374616e636520494420285555494429206973206e6f742072656769737465726564a265627a7a7231582070c645b7e75145b46b78c7271646f47e035f68ec63cf18dd486f7d19c6b7b6cb64736f6c634300050c0032";
        bytecode = Replace(bytecode, "$ecfb6c4d3c3ceff197e19e585a0a53728c$", commons_base_ErrorsLib_sol_ErrorsLib);
        const data = bytecode + client.encode("", ["address"], _service);
        const payload = client.payload(data);
        return new Promise((resolve, reject) => {
            client.deploy(payload, (err, addr) => {
                if (err)
                    reject(err);
                else {
                    const address = Buffer.from(addr).toString("hex").toUpperCase();
                    resolve(address);
                }
            });
        });
    }
    export class Contract<Tx> {
        private client: Provider<Tx>;
        public address: string;
        constructor(client: Provider<Tx>, address: string) {
            this.client = client;
            this.address = address;
        }
        LogWaitCompleted(callback: (err: Error, event: any) => void): Readable { return this.client.listen("LogWaitCompleted", this.address, callback); }
        LogWaitStarted(callback: (err: Error, event: any) => void): Readable { return this.client.listen("LogWaitStarted", this.address, callback); }
        complete(_piAddress: string, _activityInstanceId: Buffer, _txPerformer: string) {
            const data = Encode(this.client).complete(_piAddress, _activityInstanceId, _txPerformer);
            return Call<Tx, void>(this.client, this.address, data, (exec: Uint8Array) => {
                return Decode(this.client, exec).complete();
            });
        }
        completeOracle(_uuid: Buffer) {
            const data = Encode(this.client).completeOracle(_uuid);
            return Call<Tx, void>(this.client, this.address, data, (exec: Uint8Array) => {
                return Decode(this.client, exec).completeOracle();
            });
        }
    }
    export const Encode = <Tx>(client: Provider<Tx>) => { return {
        complete: (_piAddress: string, _activityInstanceId: Buffer, _txPerformer: string) => { return client.encode("867C7151", ["address", "bytes32", "address"], _piAddress, _activityInstanceId, _txPerformer); },
        completeOracle: (_uuid: Buffer) => { return client.encode("232EE528", ["bytes32"], _uuid); }
    }; };
    export const Decode = <Tx>(client: Provider<Tx>, data: Uint8Array) => { return {
        complete: (): void => { return; },
        completeOracle: (): void => { return; }
    }; };
}