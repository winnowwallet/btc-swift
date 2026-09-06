# btc-swift

The Bitcoin implementation behind [Winnow](https://github.com/winnowwallet/winnow) —
keys to broadcast with one dependency
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

## Lines of code

The [LOC workflow](https://github.com/winnowwallet/btc-swift/actions/workflows/loc.yml)
reports every pull request, push to `main`, and manual run, including changes
that only touch documentation or webpages. Open the run's summary for category
totals and download its `loc-<commit>-<attempt>` artifact for `loc.json`,
`loc.csv`, and `loc.md`. Artifacts expire after 90 days, or sooner if limited by
organization policy; reports are not committed or attached to releases.

**Total source** sums nonblank, noncomment lines in library/CLI source, tests,
webpages, and tooling/infrastructure (including workflows and build manifests).
Documentation, vectors, fixtures, lockfiles, and unknown text belong to **other
text**, which has a separate nonblank-line total. Webpages remain visible with
a zero count when absent. Fixtures take precedence over test and webpage rules;
scripts take precedence over source-language rules.

Counting uses committed Git blobs, once per tracked path, and excludes generated
fallback peers, dependency/build directories, binaries/non-UTF-8 files, symlinks,
submodules, and LFS pointers. Local edits, downloaded dependencies, and caches
cannot change a commit's report. Every excluded path and reason is recorded.
PR deltas compare the head against its merge base using the head's counting
policy for both snapshots; a rename within a category has no LOC effect.

JSON contains versioned metadata, head/base snapshots, per-file measurements,
category/language aggregates, and deltas. CSV has one row per path per snapshot,
including excluded paths. `code`, `comment`, and `blank` retain cloc's counters
where it recognizes a file; `source_loc` excludes other text, and `nonblank`
counts physical nonblank text lines. Unknown text retains its raw line counts.
LOC growth is informational; failures to count or upload fail the reporting job.

To reproduce a report locally, download the
[official cloc 2.10 Perl asset](https://github.com/AlDanial/cloc/releases/download/v2.10/cloc-2.10.pl),
then run (the reporter verifies its checksum):

```sh
python3 scripts/report-loc.py --cloc /path/to/cloc-2.10.pl \
  --ref HEAD --base-ref origin/main --output-dir /tmp/btc-swift-loc
CLOC=/path/to/cloc-2.10.pl PYTHONDONTWRITEBYTECODE=1 \
  python3 -m unittest discover -s scripts/tests -p 'test_report_loc.py' -v
```

Omit `--base-ref` for a standalone snapshot. Changes to counting rules bump
`POLICY_VERSION`; incompatible JSON/CSV changes bump `SCHEMA_VERSION` in
`scripts/report-loc.py`. No Swift build or dependency resolution is needed.

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
