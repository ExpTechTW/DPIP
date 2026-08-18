#!/usr/bin/env bash
# Everything .github/workflows/ci.yml runs, in one command.
#
#     tool/check.sh                 # cached where it is safe to cache
#     DPIP_NO_CACHE=1 tool/check.sh # run everything, trusting nothing
#
# A green run here means a green CI. The list below is the authority for that
# claim — when a step is added to ci.yml it has to be added here too, or this
# starts lying and the next person finds out from a red PR on a branch that was
# green.
#
# Ordered by how fast it fails. Format and the analyzer come first because they
# fail on files you did not touch; the shell gates are cheap and need no
# toolchain; the tests are last because they are the only part measured in
# minutes.
#
# Three steps are content-hash cached (see `cached` in dev/_lib.sh): the
# analyzer, codegen and the test suite. Together they are almost all of the
# wall-clock, and all three depend only on files — so a second run over an
# unchanged tree is free, and a one-byte edit anywhere in their inputs re-runs
# them. The cheap gates are never cached: they finish in about a second each,
# and a stale answer from a cache is worth less than that.
#
# Not run here, and on purpose:
#   - `pub get`. CI installs dependencies; a developer already has them, and
#     `check/pubspec_lock.sh` is what catches a lockfile that disagrees.
#   - actionlint. CI downloads it; nothing pins it locally.
#   - `check/commits.sh`. It belongs to `tool/commit.sh`, which is where you
#     are when a commit message is the thing being decided.
source "$(dirname "${BASH_SOURCE[0]}")/dev/_lib.sh"
cd "$(repo_root)"

# What each cached step reads. Anything a step's result depends on has to be in
# its list, or the cache will happily hand back an answer about a file that has
# since changed — the one failure mode of a cache like this, and a silent one.
readonly -a CODE_INPUTS=(
  lib test tool
  pubspec.yaml pubspec.lock analysis_options.yaml l10n.yaml build.yaml
)
readonly -a TEST_INPUTS=("${CODE_INPUTS[@]}" assets shaders)

step 'format + analyze'
cached analyze "$(cache_key "${CODE_INPUTS[@]}")" tool/dev/analyze.sh

# Five of these finish in under a quarter of a second and are run every time:
# hashing their inputs would cost as much as running them, and a cache that
# saves nothing is a cache that can only be wrong.
for gate in tooling l10n pubspec_lock notification_sounds build_info; do
  step "check/$gate"
  "tool/check/$gate.sh"
done

# These two walk every .dart file in lib/ and take 5.9 s and 2.2 s, which is
# most of what is left once the toolchain steps are cached. Both read lib/ and
# nothing else, so the key is narrow and invalidates exactly when it should.
for gate in layering storage; do
  step "check/$gate"
  cached "$gate" "$(cache_key lib "tool/check/$gate.sh")" "tool/check/$gate.sh"
done

step 'codegen is up to date'
# A stale *.freezed.dart / *.g.dart compiles and ships, so CI regenerates and
# fails if anything moved. CI can do that with `git diff --exit-code` because
# its checkout is clean; here it cannot — a developer running this has
# uncommitted work by definition, and diffing against HEAD would report their
# own edits as stale codegen.
#
# So compare the generated files against *themselves*, before and after. That
# asks the real question — does a fresh run produce what is already on disk —
# and it is indifferent to everything else in the tree.
#
# build_info.g.dart is excluded because it can never match: it holds the hash
# of the commit it is committed in.
generated_hashes() {
  git ls-files -co --exclude-standard -- '*.g.dart' '*.freezed.dart' |
    grep -v '^lib/core/build_info\.g\.dart$' |
    LC_ALL=C sort | tr '\n' '\0' | xargs -0 shasum -a 256
}

codegen_check() {
  local before after
  before="$(generated_hashes)"
  tool/dev/codegen.sh
  after="$(generated_hashes)"
  [[ $before == "$after" ]] && return 0

  printf 'Generated files changed — the committed codegen is stale:\n' >&2
  diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") |
    sed -n 's/^[<>] *[0-9a-f]*  */  /p' | LC_ALL=C sort -u >&2
  return 1
}
cached codegen "$(cache_key "${CODE_INPUTS[@]}")" codegen_check

step 'test'
cached test "$(cache_key "${TEST_INPUTS[@]}")" tool/dev/test.sh

step 'all gates passed'
