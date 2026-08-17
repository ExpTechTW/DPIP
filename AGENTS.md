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

Flutter and Dart are pinned by **mise** — run tools through it, so CI and every
laptop use the same version:

```sh
mise exec -- flutter analyze
```

- After changing `@freezed` / `@JsonSerializable` models:
  `mise exec -- dart run build_runner build --delete-conflicting-outputs`
- After editing ARB files, localizations regenerate on the next build
  (`generate: true`); by hand with `mise exec -- flutter gen-l10n`
- Format with `mise exec -- dart format lib test tool`

## Running

```sh
tool/run.sh -d "iPhone 17 Pro"
```

`flutter run` on the pinned toolchain with the log coloured — arguments pass
through untouched, and hot reload still works, because the tool reads
`supportsColor` from stdout and its keystrokes from stdin, and a pipe only
touches the first.

Select the device with `-d <name|id>`. A bare `flutter run ios` treats `ios` as
a target Dart file and fails with `Target file "ios" not found`.

- `tool/run.sh` is `mise exec -- flutter run … | tool/colorize_logs.sh`.
  Colour is added by the pipe, not by the app: on iOS an escape sequence cannot
  survive the trip, because the platform's log path escapes the escape
  character and even a terminal that supports ANSI then prints it
  (flutter/flutter#20663). `dart:developer`'s `log` does deliver them, but
  truncates past ~128 characters — which is where the diagnostic lines are. The
  pipe has neither problem, and drops the `flutter: ` prefix as well.
- If `flutter run` / `pub get` stalls at **Downloading packages**, resolve from
  the local cache first: `mise exec -- flutter pub get --offline`, then re-run.
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
  `tool/release_notes.sh` with a single regular expression. Categories are
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
tool/check_commits.sh origin/main..HEAD
tool/check_layering.sh
tool/check_l10n.sh
tool/check_storage.sh
tool/check_pubspec_lock.sh
tool/check_notification_sounds.sh
mise exec -- dart format --set-exit-if-changed lib test tool
mise exec -- dart run build_runner build --delete-conflicting-outputs   # then git diff --exit-code
mise exec -- flutter analyze
mise exec -- flutter test
```

The bash gates need only bash and python3, so they fail fast without the
toolchain. `.github/workflows/ci.yml` runs the same list and must stay green;
`android.yml` / `ios.yml` build artifacts and `review.yml` adds an automated PR
review.

Safety-critical seismic maths is pinned by golden tests
(`test/features/earthquake/eew_estimator_test.dart`). If you change the EEW
estimator, update those goldens deliberately.

## Versions

Nobody edits a version by hand. `tool/version.sh` derives all three values from
git state and CI passes them to the build:

| | | |
|---|---|---|
| `label` | what a human sees | `26.1` · `26w33a` |
| `train` | what Apple is told | `26.1` |
| `code` | what both stores sort by | `426000298` |

Every commit on `main` publishes a snapshot; a `v*` tag publishes a release.
`pubspec.yaml`'s `version:` is a placeholder for local runs only.

Read the header of `tool/version.sh` before changing any of it. Every constant
there is a fact about what has already shipped to a store, and a store refuses,
permanently, any build whose ordinal is not above the last it accepted —
deleting the build does not release the number.

## Reporting

Say what was actually done. If a test fails, show the output; if a step was
skipped, say so. Do not report work as finished until it is verified — the list
under *Before pushing* is what "verified" means here.
