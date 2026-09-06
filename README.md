# Bitcoin modules moved into Winnow

Development continues in [winnowwallet/winnow](https://github.com/winnowwallet/winnow).
The app, Bitcoin modules, CLI, story driver, fuzz harness, tests and website share
one package, one dependency lockfile and one release workflow there.

The complete implementation from this repository is included in
[the Winnow consolidation](https://github.com/winnowwallet/winnow/tree/1548afc00a5fa304f0fe8d0f5664e5c5df16c383).
The [CI and release guide](https://github.com/winnowwallet/winnow/blob/1548afc00a5fa304f0fe8d0f5664e5c5df16c383/.github/internal/ci-release.md)
explains the shared checks and development tools.

This repository is archived. Existing tags and releases remain available for
historical checkouts; there is no separate public library product or new release
train here. Current development belongs in Winnow.
