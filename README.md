# btc-swift

The Bitcoin implementation behind [Winnow](https://github.com/winnowwallet/winnow) —
keys to broadcast in ~10,600 lines of Swift, one dependency
([swift-secp256k1](https://github.com/21-DOT-DEV/swift-secp256k1), Bitcoin
Core's libsecp256k1), every function at seven decision paths or under, enforced in CI.

- `BitcoinCore` — crypto, keys (BIP39/32/86), Taproot (BIP341), descriptors
  (BIP380/387/389/390), MuSig2 (BIP327)
- `BitcoinP2P` — wire protocol, peers, header chain, BIP157/158 filter sync,
  mempool windows, tx broadcast
- `WalletCore` — wallet/vault logic, sighash + signing, PSBTv2
  (BIP370/371/373), coin selection, fee policy, import bundles
- `BlockchainBackend` — isolated HTTP explorer client, deliberately never
  instantiated by the wallet (that absence is a pinned invariant)

## The CLI

`btc-swift` is the library's scriptable face — offline primitives, no
network, an audit aid rather than a wallet:

```sh
swift run btc-swift derive "tr([…]tpub…/0/*)" --network signet --count 5
swift run btc-swift decode-tx <hex>
swift run btc-swift decode-psbt <base64>
swift run btc-swift combine-psbt <base64> <base64…>
swift run btc-swift finalize-psbt <base64>
swift run btc-swift filter-contains <filter-hex> <block-hash-hex> <script-hex…>
```

`WinnowSoak` is the sustained-signet soak driver the security register's
long-run evidence comes from.

## Tests

517 tests in 90 suites: BIP vectors, unit, loopback protocol suites, and a
differential battery (`WINNOW_DIFF=1 swift test --no-parallel`) that rebuilds
filters, headers, sighashes, and PSBTs field-by-field against a Bitcoin Core
node on a reproducible signet — `scripts/signet-fixture up` builds the node
from a committed dev key. The deterministic fuzzer lives beside this repo in
[winnow-fuzz](https://github.com/winnowwallet/winnow-fuzz).

## Consumers

[winnow](https://github.com/winnowwallet/winnow) (the iOS wallet),
[winnow-story](https://github.com/winnowwallet/winnow-story), and
[winnow-fuzz](https://github.com/winnowwallet/winnow-fuzz) consume the
library products. The wallet pins an exact published library version;
the library and wallet use independent release versions.

## Releases

[0.1.0](https://github.com/winnowwallet/btc-swift/releases/tag/v0.1.0) is the
first standalone library release. Swift package consumers can pin it with:

```swift
.package(url: "https://github.com/winnowwallet/btc-swift", exact: "0.1.0")
```

Release tags name fixed commits. Further changes ship in a new version;
published tags are never moved. During the 0.x series, API changes may
require updates in consumers, which should bump their exact version
deliberately after running their own checks.

MIT.
