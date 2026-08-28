import BitcoinCore
import BitcoinP2P
import Foundation
import WalletCore

/// The library's scriptable face: offline primitives over the same public
/// API the wallet uses, one subcommand per question. No network, no keys
/// unless handed one on the command line, no dependencies beyond the
/// library itself — this is a dev tool and an audit aid, not a wallet.
///
///   btc-swift derive <descriptor> [--network signet|mainnet] [--chain 0|1] [--count N]
///   btc-swift decode-tx <hex>
///   btc-swift decode-psbt <base64>
///   btc-swift combine-psbt <base64> <base64...>
///   btc-swift finalize-psbt <base64>
///   btc-swift filter-contains <filter-hex> <block-hash-hex> <script-hex...>

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("btc-swift: " + message + "\n").utf8))
    exit(1)
}

func flag(_ name: String, in args: inout [String]) -> String? {
    guard let index = args.firstIndex(of: name), index + 1 < args.count else { return nil }
    let value = args[index + 1]
    args.removeSubrange(index ... index + 1)
    return value
}

func emit(_ object: Any) {
    guard let data = try? JSONSerialization.data(
        withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
        let text = String(data: data, encoding: .utf8)
    else { fail("could not encode output") }
    print(text)
}

func txObject(_ tx: Transaction) -> [String: Any] {
    [
        "txid": tx.txid.displayHex,
        "version": tx.version,
        "locktime": tx.locktime,
        "inputs": tx.inputs.map { input in
            [
                "txid": input.previousOutput.txid.displayHex,
                "vout": input.previousOutput.vout,
                "sequence": input.sequence,
                "witnessItems": input.witness.count,
            ] as [String: Any]
        },
        "outputs": tx.outputs.map { output in
            [
                "value": output.value,
                "scriptPubKey": output.scriptPubKey.hex,
            ] as [String: Any]
        },
        "vsize": TransactionBuilder.vsize(of: tx),
    ]
}

var arguments = Array(CommandLine.arguments.dropFirst())
guard let command = arguments.first else {
    fail("usage: btc-swift <derive|decode-tx|decode-psbt|combine-psbt|finalize-psbt|filter-contains> …")
}
arguments.removeFirst()

do {
    switch command {
    case "derive":
        let networkName = flag("--network", in: &arguments) ?? "signet"
        guard let network = BitcoinNetwork(rawValue: networkName) else {
            fail("unknown network \(networkName)")
        }
        let chain = Int(flag("--chain", in: &arguments) ?? "0") ?? 0
        let count = UInt32(flag("--count", in: &arguments) ?? "5") ?? 5
        guard let descriptorText = arguments.first else { fail("derive needs a descriptor") }
        let descriptor = try Descriptor(descriptorText)
        let hdNetwork: HDKey.Network = network == .mainnet ? .mainnet : .testnet
        let hrp = network == .mainnet ? "bc" : "tb"
        var rows: [[String: Any]] = []
        for index in 0 ..< count {
            let derived = try descriptor.derived(index: index, network: hdNetwork)[chain]
            let script = derived.scriptPubKey
            rows.append([
                "index": index,
                "scriptPubKey": script.hex,
                "address": (try? BIP86.address(internalKey: script.dropFirst(2), hrp: hrp)) ?? "",
            ])
        }
        emit(["descriptor": descriptorText, "network": networkName, "chain": chain,
              "derivations": rows])

    case "decode-tx":
        guard let hex = arguments.first, let data = Data(hex: hex) else {
            fail("decode-tx needs transaction hex")
        }
        emit(txObject(try Transaction.decode(data)))

    case "decode-psbt":
        guard let base64 = arguments.first, let psbt = try? PSBT(base64: base64) else {
            fail("decode-psbt needs a Base64 PSBT")
        }
        emit([
            "txVersion": psbt.txVersion,
            "inputs": psbt.inputs.enumerated().map { index, input in
                [
                    "index": index,
                    "previousTxid": input.previousTxid.map(\.displayHex) ?? "",
                    "vout": input.outputIndex ?? 0,
                    "hasWitnessUTXO": input.witnessUTXO != nil,
                    "tapKeySig": input.tapKeySignature != nil,
                    "tapScriptSigs": input.tapScriptSignatures.count,
                ] as [String: Any]
            },
            "outputs": psbt.outputs.map { output in
                [
                    "amount": output.amount ?? 0,
                    "script": output.script?.hex ?? "",
                ] as [String: Any]
            },
        ])

    case "combine-psbt":
        guard arguments.count >= 2 else { fail("combine-psbt needs two or more PSBTs") }
        var psbts = arguments.map { base64 -> PSBT in
            guard let psbt = try? PSBT(base64: base64) else { fail("bad PSBT") }
            return psbt
        }
        let first = psbts.removeFirst()
        print(try first.combined(with: psbts).base64)

    case "finalize-psbt":
        guard let base64 = arguments.first, var psbt = try? PSBT(base64: base64) else {
            fail("finalize-psbt needs a Base64 PSBT")
        }
        try psbt.finalize()
        print(try psbt.extractedTransaction().serialized(includeWitness: true).hex)

    case "filter-contains":
        guard arguments.count >= 3,
              let filterData = Data(hex: arguments[0]),
              let blockHash = Data(hex: arguments[1])
        else { fail("filter-contains <filter-hex> <block-hash-display-hex> <script-hex…>") }
        var reader = ByteReader(filterData)
        let n = UInt32(try reader.readVarInt())
        let filter = try GCSFilter(p: GCSFilter.defaultP, m: GCSFilter.defaultM,
                                   key: Data(Data(blockHash.reversed()).prefix(16)),
                                   n: n, encoded: reader.readBytes(reader.remaining))
        var results: [[String: Any]] = []
        for scriptHex in arguments.dropFirst(2) {
            guard let script = Data(hex: scriptHex) else { fail("bad script hex \(scriptHex)") }
            results.append(["script": scriptHex, "matches": filter.contains(script)])
        }
        emit(["results": results])

    default:
        fail("unknown command \(command)")
    }
} catch {
    fail("\(error)")
}
