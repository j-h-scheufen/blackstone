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
export module AgreementsAPI {
    export function Deploy<Tx>(client: Provider<Tx>, commons_standards_ERC165Utils_sol_ERC165Utils: string): Promise<string> {
        let bytecode = "610b30610026600b82828239805160001a60731461001957fe5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600436106100405760003560e01c806306fb063b1461004557806360b7f43d146100a1575b600080fd5b6100876004803603602081101561005b57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610165565b604051808215151515815260200191505060405180910390f35b8180156100ad57600080fd5b506100f0600480360360208110156100c457600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919050505061037c565b604051808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019250505060405180910390f35b600080829050600080600090505b8273ffffffffffffffffffffffffffffffffffffffff16637f8093816040518163ffffffff1660e01b815260040160206040518083038186803b1580156101b957600080fd5b505afa1580156101cd573d6000803e3d6000fd5b505050506040513d60208110156101e357600080fd5b810190808051906020019092919050505081101561036f578273ffffffffffffffffffffffffffffffffffffffff1663f4b9d96e8473ffffffffffffffffffffffffffffffffffffffff166379ce3cb2846040518263ffffffff1660e01b81526004018082815260200191505060206040518083038186803b15801561026857600080fd5b505afa15801561027c573d6000803e3d6000fd5b505050506040513d602081101561029257600080fd5b81019080805190602001909291905050506040518263ffffffff1660e01b8152600401808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001915050604080518083038186803b15801561030257600080fd5b505afa158015610316573d6000803e3d6000fd5b505050506040513d604081101561032c57600080fd5b81019080805190602001909291908051906020019092919050505090508092505060008214156103625760009350505050610377565b8080600101915050610173565b506001925050505b919050565b600080600083905060008060008373ffffffffffffffffffffffffffffffffffffffff16637f8093816040518163ffffffff1660e01b815260040160206040518083038186803b1580156103cf57600080fd5b505afa1580156103e3573d6000803e3d6000fd5b505050506040513d60208110156103f957600080fd5b81019080805190602001909291905050509050600091505b80821015610533578373ffffffffffffffffffffffffffffffffffffffff166379ce3cb2836040518263ffffffff1660e01b81526004018082815260200191505060206040518083038186803b15801561046a57600080fd5b505afa15801561047e573d6000803e3d6000fd5b505050506040513d602081101561049457600080fd5b810190808051906020019092919050505092503373ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff16148061050c57503273ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff16145b156105265782955082945085859550955050505050610a18565b8180600101925050610411565b600091505b80821015610a13578373ffffffffffffffffffffffffffffffffffffffff166379ce3cb2836040518263ffffffff1660e01b81526004018082815260200191505060206040518083038186803b15801561059157600080fd5b505afa1580156105a5573d6000803e3d6000fd5b505050506040513d60208110156105bb57600080fd5b8101908080519060200190929190505050925073__$fdd731fada9905693765f0d2a681d4c856$__6392302b87846105f1610a1d565b6040518363ffffffff1660e01b8152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191681526020019250505060206040518083038186803b15801561069657600080fd5b505af41580156106aa573d6000803e3d6000fd5b505050506040513d60208110156106c057600080fd5b810190808051906020019092919050505015610a065760008473ffffffffffffffffffffffffffffffffffffffff16633c0e5245858773ffffffffffffffffffffffffffffffffffffffff166380c86ba76040518163ffffffff1660e01b815260040160206040518083038186803b15801561073b57600080fd5b505afa15801561074f573d6000803e3d6000fd5b505050506040513d602081101561076557600080fd5b8101908080519060200190929190505050886040518463ffffffff1660e01b8152600401808473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018381526020018273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001935050505060206040518083038186803b15801561081157600080fd5b505afa158015610825573d6000803e3d6000fd5b505050506040513d602081101561083b57600080fd5b810190808051906020019092919050505090508373ffffffffffffffffffffffffffffffffffffffff1663ddc5dd5133836040518363ffffffff1660e01b8152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018281526020019250505060206040518083038186803b1580156108d357600080fd5b505afa1580156108e7573d6000803e3d6000fd5b505050506040513d60208110156108fd57600080fd5b810190808051906020019092919050505015610929573396508395508686965096505050505050610a18565b8373ffffffffffffffffffffffffffffffffffffffff1663ddc5dd5132836040518363ffffffff1660e01b8152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018281526020019250505060206040518083038186803b1580156109ae57600080fd5b505afa1580156109c2573d6000803e3d6000fd5b505050506040513d60208110156109d857600080fd5b810190808051906020019092919050505015610a04573296508395508686965096505050505050610a18565b505b8180600101925050610538565b505050505b915091565b600060405160200180807f617574686f72697a655573657228616464726573732c62797465733332290000815250601e0190506040516020818303038152906040528051906020012060405160200180807f72656d6f7665557365722861646472657373290000000000000000000000000081525060130190506040516020818303038152906040528051906020012060405160200180807f6164645573657228616464726573732900000000000000000000000000000000815250601001905060405160208183030381529060405280519060200120181890509056fea265627a7a72315820624dd7d1ac87ff9fe95d5a638c998877b604d0df60b8389d9a7e2f2aacbbd3b664736f6c634300050c0032";
        bytecode = Replace(bytecode, "$fdd731fada9905693765f0d2a681d4c856$", commons_standards_ERC165Utils_sol_ERC165Utils);
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
        isFullyExecuted(_agreementAddress: string) {
            const data = Encode(this.client).isFullyExecuted(_agreementAddress);
            return Call<Tx, [boolean]>(this.client, this.address, data, true, (exec: Uint8Array) => {
                return Decode(this.client, exec).isFullyExecuted();
            });
        }
    }
    export const Encode = <Tx>(client: Provider<Tx>) => { return {
        isFullyExecuted: (_agreementAddress: string) => { return client.encode("06FB063B", ["address"], _agreementAddress); }
    }; };
    export const Decode = <Tx>(client: Provider<Tx>, data: Uint8Array) => { return {
        isFullyExecuted: (): [boolean] => { return client.decode(data, ["bool"]); }
    }; };
}