# Working in this repository

DPIP is a Taiwan disaster-prevention app: a clean Flutter 3.47 rewrite,
feature-first architecture.

## Where things are written down

Each topic has exactly one home. Nothing below is repeated elsewhere — the
other files point here, and this file points at them.

| File | Owns |
|---|---|
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Folder layout, layer rules, and every subsystem contract: logging, state, networking, data & errors, realtime, calibrated time, async-state UI, push, LoRa mesh, persistence |
| **[DESIGN.md](DESIGN.md)** | Design tokens, colour, spacing, motion, typography, icons, localization, shared components |
| **[api.md](api.md)** | API endpoints, the region map, and which tier each one lives on |
| **[commit.md](commit.md)** | Commit format, in full (中文) |
| **[README.md](README.md)** | What DPIP is, for people who do not work on it |
| this file | Toolchain, running, verification, versions |

## Toolchain

**mise is required.** Not preferred — required. Without it the scripts refuse to
run and tell you how to install it, because there is nothing to pin against and
a build off the wrong SDK looks exactly like a build off the right one.

Flutter and Dart are pinned in `mise.toml`, and **every workflow has a script
under `tool/`**. Never type the toolchain yourself — not `flutter`, not `dart`,
and not `mise exec`. A shell's PATH is resolved once and `mise activate` caches
it, so a toolchain bump leaves the old SDK on PATH until the session is
replaced, and a run against the wrong SDK announces nothing: it builds, it runs,
its tests pass.

Three things enforce it, none of which relies on anybody remembering:

| Where | What it refuses |
|---|---|
| `require_mise` in `tool/dev/_lib.sh` | no mise, no `mise.toml`, or a flutter that resolves outside mise's own installs — the last one is the dangerous case, because `mise exec` will happily forward to a system SDK |
| `tool/check/tooling.sh` | a bare toolchain command in the docs or CI; and, for every script in `tool/`, one that does not parse, is not executable, has no shebang, or reaches `flutter` / `dart` / `mise exec` without going through `pinned` |
| `tool/run.sh` | runs both before it starts anything (0.34 s) |

```sh
tool/dev/analyze.sh
```

| Do this | Run |
|---|---|
| Start the app | `tool/run.sh` (see [Running](#running)) |
| Run the tests | `tool/dev/test.sh` |
| Format + analyze | `tool/dev/analyze.sh` |
| Reformat in place | `tool/dev/format.sh` |
| Resolve dependencies | `tool/dev/deps.sh` (`--offline` when pub.dev stalls) |
| Regenerate after `@freezed` / `@JsonSerializable` edits | `tool/dev/codegen.sh` |
| Regenerate l10n by hand (a build does it anyway) | `tool/dev/l10n.sh` |
| Throw away the build output | `tool/dev/clean.sh` |
| Release build | `tool/dev/build.sh {android\|bundle\|ios}` |
| Everything CI runs | `tool/check.sh` (content-hash cached: ~1 s when nothing changed) |
| Before writing any commit | `tool/commit.sh` (see [commit.md](commit.md)) |
| One-time git-hook setup | `tool/dev/setup.sh` (`tool/run.sh` does it for you) |

`tool/` is organised by what a script is for: `dev/` daily workflows, `check/`
the CI gates, `release/` versioning and notes, `gen/` asset and code
generators, `internal/` pieces other scripts call and nobody runs by hand.

## Running

```sh
tool/run.sh -d "iPhone 17 Pro"
```

On Windows, `tool\run.ps1 -d "Pixel 9"` — or `bash tool/run.sh` under Git Bash
or WSL, which is the one that colours the log. `run.ps1` deliberately does not
pipe: `$LASTEXITCODE` is unreliable when a native command feeds a cmdlet
(PowerShell/PowerShell#19848), and a wrapper that reports a failed build as a
success is worse than an uncoloured one.

**This is the only supported way to start the app.** Every other way of
starting it is wrong in a way nothing tells you about, so **a debug build
started any other way refuses to run** and prints the command to use instead.

Arguments pass through untouched, and hot reload still works: the tool reads
`supportsColor` from stdout and its keystrokes from stdin, and a pipe only
touches the first.

Select the device with `-d <name|id>`. A bare `flutter run ios` treats `ios` as
a target Dart file and fails with `Target file "ios" not found`.

- `tool/run.sh` runs the pinned `flutter run` and pipes it through
  `tool/internal/colorize_logs.sh`. Colour is added by the pipe, not by the app: on iOS an escape sequence cannot
  survive the trip, because the platform's log path escapes the escape
  character and even a terminal that supports ANSI then prints it
  (flutter/flutter#20663). `dart:developer`'s `log` does deliver them, but
  truncates past ~128 characters — which is where the diagnostic lines are. The
  pipe has neither problem, and drops the `flutter: ` prefix as well.
- If a launch stalls at **Downloading packages**, resolve from the local cache
  first with `tool/dev/deps.sh --offline`, then re-run.
- The visible simulator window in Xcode 26+ is **DeviceHub.app** — it replaced
  `Simulator.app`, and `open -a Simulator` no longer works. `flutter run` boots
  the simulator headless, so open it separately to see or touch anything:

  ```sh
  open "$(xcode-select -p)/../Applications/DeviceHub.app"
  ```

## Commits

The full specification, with examples, is **[commit.md](commit.md)**. The parts
worth knowing before writing one:

```
<type>(<scope>): <English summary>

New(zh-Hant): <一行，使用者感覺得到的事>
New(en-US): <the same, in English>
```

- **Each `Category(locale):` line is one changelog entry**, extracted by
  `tool/release/notes.sh` with a single regular expression. Categories are
  `New` / `Optimization` / `Fix`; `zh-Hant` and `en-US` are required and the
  app's other locales are optional.
- **There is no prose body.** Why it was done, what was tried, what bit you —
  all of it goes in a code comment, where the next person to touch the code
  will see it. Nobody reading a changelog can use any of it.
- `feat` / `fix` / `perf` need at least one entry line; everything else needs
  none and simply does not appear in a note.
- The category is **declared, not inferred from the type** — so a user-visible
  fix that lives in a `chore:` commit still reaches the changelog, which the
  old type-derived mapping silently dropped.
- **Rebase, never merge, and never leave the branch behind.** CI refuses both:
  a merge commit is invisible to the gate (`--no-merges`), so anything arriving
  through one is never judged, and a branch that is behind was tested against a
  main that no longer exists. `git rebase origin/main` and force-with-lease.
- **One thing per commit.** No gate can check this — whether two changes are
  the same thing is a judgement — so it is on you and on review.
- **Never** add a `Co-Authored-By:` trailer, `Generated with …`, 🤖, a model
  name or an agent's name. A commit is authored by a person; an agent that
  writes itself into the record makes the history lie about who is accountable,
  and that record is what someone reads years later to ask why.

## Before pushing

Everything CI runs, in order. All of it must be clean:

```sh
tool/check.sh
```

That is the whole list, and it is the same list `.github/workflows/ci.yml`
runs — CI calls these scripts rather than naming the commands itself, so the
two cannot drift. Individually, if you want to fail faster:

```sh
tool/check/commits.sh origin/main..HEAD
tool/check/layering.sh
tool/check/l10n.sh
tool/check/storage.sh
tool/check/pubspec_lock.sh
tool/check/notification_sounds.sh
tool/check/tooling.sh
tool/dev/analyze.sh
tool/dev/codegen.sh          # then git diff --exit-code
tool/dev/test.sh
```

The bash gates need only bash and python3, so they fail fast without the
toolchain. `.github/workflows/ci.yml` must stay green;
`android.yml` / `ios.yml` build artifacts and `review.yml` adds an automated PR
review.

Safety-critical seismic maths is pinned by golden tests
(`test/features/earthquake/eew_estimator_test.dart`). If you change the EEW
estimator, update those goldens deliberately.

## Versions

Nobody edits a version by hand. `tool/release/version.sh` derives all three values from
git state and CI passes them to the build:

| | | |
|---|---|---|
| `label` | what a human sees | `26.1` · `26w33a` |
| `train` | what Apple is told | `26.1` |
| `code` | what both stores sort by | `426000298` |

Every commit on `main` publishes a snapshot; a `v*` tag publishes a release.
`pubspec.yaml`'s `version:` is a placeholder for local runs only.

Read the header of `tool/release/version.sh` before changing any of it. Every constant
there is a fact about what has already shipped to a store, and a store refuses,
permanently, any build whose ordinal is not above the last it accepted —
deleting the build does not release the number.

## Reporting

Say what was actually done. If a test fails, show the output; if a step was
skipped, say so. Do not report work as finished until it is verified — the list
under *Before pushing* is what "verified" means here.
