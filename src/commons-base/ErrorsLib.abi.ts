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
export module ErrorsLib {
    export function Deploy<Tx>(client: Provider<Tx>): Promise<string> {
        let bytecode = "610b70610026600b82828239805160001a60731461001957fe5b30600052607381538281f3fe730000000000000000000000000000000000000000301460806040526004361061004b5760003560e01c80633ef7bf121461005057806359a136991461025057806375d7bdef146104b2575b600080fd5b81801561005c57600080fd5b5061024e6004803603608081101561007357600080fd5b81019080803590602001909291908035906020019064010000000081111561009a57600080fd5b8201836020820111156100ac57600080fd5b803590602001918460018302840111640100000000831117156100ce57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f8201169050808301925050505050505091929192908035906020019064010000000081111561013157600080fd5b82018360208201111561014357600080fd5b8035906020019184600183028401116401000000008311171561016557600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290803590602001906401000000008111156101c857600080fd5b8201836020820111156101da57600080fd5b803590602001918460018302840111640100000000831117156101fc57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f8201169050808301925050505050505091929192905050506106a7565b005b6104376004803603606081101561026657600080fd5b810190808035906020019064010000000081111561028357600080fd5b82018360208201111561029557600080fd5b803590602001918460018302840111640100000000831117156102b757600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f8201169050808301925050505050505091929192908035906020019064010000000081111561031a57600080fd5b82018360208201111561032c57600080fd5b8035906020019184600183028401116401000000008311171561034e57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290803590602001906401000000008111156103b157600080fd5b8201836020820111156103c357600080fd5b803590602001918460018302840111640100000000831117156103e557600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290505050610824565b6040518080602001828103825283818151815260200191508051906020019080838360005b8381101561047757808201518184015260208101905061045c565b50505050905090810190601f1680156104a45780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6106a5600480360360808110156104c857600080fd5b81019080803515159060200190929190803590602001906401000000008111156104f157600080fd5b82018360208201111561050357600080fd5b8035906020019184600183028401116401000000008311171561052557600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f8201169050808301925050505050505091929192908035906020019064010000000081111561058857600080fd5b82018360208201111561059a57600080fd5b803590602001918460018302840111640100000000831117156105bc57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f8201169050808301925050505050505091929192908035906020019064010000000081111561061f57600080fd5b82018360208201111561063157600080fd5b8035906020019184600183028401116401000000008311171561065357600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290505050610a09565b005b837f8b8c9c730ae91e253fa9496c760e3051874e6c04151f785ce9e47b28aa5e1ca284848460405180806020018060200180602001848103845287818151815260200191508051906020019080838360005b838110156107145780820151818401526020810190506106f9565b50505050905090810190601f1680156107415780820380516001836020036101000a031916815260200191505b50848103835286818151815260200191508051906020019080838360005b8381101561077a57808201518184015260208101905061075f565b50505050905090810190601f1680156107a75780820380516001836020036101000a031916815260200191505b50848103825285818151815260200191508051906020019080838360005b838110156107e05780820151818401526020810190506107c5565b50505050905090810190601f16801561080d5780820380516001836020036101000a031916815260200191505b50965050505050505060405180910390a250505050565b606060008451141561083b57610838610ac1565b93505b83610844610afe565b8461084d610afe565b856040516020018086805190602001908083835b602083106108845780518252602082019150602081019050602083039250610861565b6001836020036101000a03801982511681845116808217855250505050505090500185805190602001908083835b602083106108d557805182526020820191506020810190506020830392506108b2565b6001836020036101000a03801982511681845116808217855250505050505090500184805190602001908083835b602083106109265780518252602082019150602081019050602083039250610903565b6001836020036101000a03801982511681845116808217855250505050505090500183805190602001908083835b602083106109775780518252602082019150602081019050602083039250610954565b6001836020036101000a03801982511681845116808217855250505050505090500182805190602001908083835b602083106109c857805182526020820191506020810190506020830392506109a5565b6001836020036101000a0380198251168184511680821785525050505050509050019550505050505060405160208183030381529060405290509392505050565b8315610abb57610a1a838383610824565b6040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825283818151815260200191508051906020019080838360005b83811015610a80578082015181840152602081019050610a65565b50505050905090810190601f168015610aad5780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b50505050565b60606040518060400160405280600681526020017f4552523530300000000000000000000000000000000000000000000000000000815250905090565b60606040518060400160405280600281526020017f3a3a00000000000000000000000000000000000000000000000000000000000081525090509056fea265627a7a723158207ff7635b8b672eadcbb3583ebcf18bf346a68f6d4f91ca242194a43355d076c064736f6c634300050c0032";
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
        LogError(callback: (err: Error, event: any) => void): Readable { return this.client.listen("LogError", this.address, callback); }
        format(_code: string, _location: string, _message: string) {
            const data = Encode(this.client).format(_code, _location, _message);
            return Call<Tx, [string]>(this.client, this.address, data, true, (exec: Uint8Array) => {
                return Decode(this.client, exec).format();
            });
        }
        revertIf(_condition: boolean, _code: string, _location: string, _message: string) {
            const data = Encode(this.client).revertIf(_condition, _code, _location, _message);
            return Call<Tx, void>(this.client, this.address, data, true, (exec: Uint8Array) => {
                return Decode(this.client, exec).revertIf();
            });
        }
    }
    export const Encode = <Tx>(client: Provider<Tx>) => { return {
        format: (_code: string, _location: string, _message: string) => { return client.encode("59A13699", ["string", "string", "string"], _code, _location, _message); },
        revertIf: (_condition: boolean, _code: string, _location: string, _message: string) => { return client.encode("75D7BDEF", ["bool", "string", "string", "string"], _condition, _code, _location, _message); }
    }; };
    export const Decode = <Tx>(client: Provider<Tx>, data: Uint8Array) => { return {
        format: (): [string] => { return client.decode(data, ["string"]); },
        revertIf: (): void => { return; }
    }; };
}