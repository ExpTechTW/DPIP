# AGENTS.md

Rules for any agent working in this repository. `CLAUDE.md` carries the
architecture and the conventions for the code itself; this file is about how
work enters the repository.

## Commits

The full specification, with examples, is in **[commit.md](commit.md)** (中文).
The short version:

```
<type>(<scope>): <English summary>

<English body>

=== 中文 ===
<中文標題>
<中文說明>
```

- The summary is **plain-ASCII English**, ≤72 characters, imperative, no
  trailing period. `<type>` is one of `feat` `fix` `perf` `refactor` `docs`
  `test` `chore` `build` `ci` `style` `revert`.
- `feat` / `fix` / `perf` **must** carry both languages. Those three are the
  ones published, and the commit message *is* the release note — there is no
  separate changelog to fix it in afterwards.
- Everything else may be a summary line alone.
- A change that affects one platform carries a `Platform: android` or
  `Platform: ios` trailer; omit it when both are affected.
- **One thing per commit.** Two features in one commit become one changelog
  entry that has to pick a category, cannot be reverted separately, and cannot
  be isolated by `git bisect`. No gate can check this — whether two changes are
  "the same thing" is a judgement — so it is on you and on review.
- **Write down everything the commit changes.** The release note is generated
  from the message, so anything left out is invisible to users, and the message
  cannot be edited once pushed.

### Never attribute the tool

Do **not** add, in any form:

- `Co-Authored-By:` trailers
- `Generated with …`, 🤖, a model name, or an agent's name

A commit is authored by a person. An agent that writes itself into the record
makes the history lie about who is accountable for the change — and that
record is what someone reads years later when they need to ask why.

`tool/check_commits.sh` enforces all of this and CI fails the build. A commit
message cannot be edited after the fact, so a rejected one has to be fixed by
`git rebase -i` and `git push --force-with-lease`. Run the gate locally before
pushing:

```sh
tool/check_commits.sh origin/main..HEAD
```

## Before pushing

Everything CI runs, in order — all of it must be clean:

```sh
tool/check_layering.sh
tool/check_l10n.sh
tool/check_storage.sh
tool/check_pubspec_lock.sh
tool/check_commits.sh origin/main..HEAD
mise exec -- dart format --set-exit-if-changed lib test tool
mise exec -- dart run build_runner build --delete-conflicting-outputs
mise exec -- flutter analyze
mise exec -- flutter test
```

Tools go through `mise exec --`; see `CLAUDE.md` for why.

## Versions

Nobody edits a version by hand. `tool/version.sh` derives all three values from
git state, and CI passes them to the build:

| | | |
|---|---|---|
| `label` | what a human sees | `26.1` · `26w33a` |
| `train` | what Apple is told | `26.1` |
| `code` | what both stores sort by | `426000298` |

`pubspec.yaml`'s `version:` is a placeholder for local runs only. Read the
header of `tool/version.sh` before changing any of it — every constant in there
is a fact about what has already shipped to a store, and a store refuses,
permanently, any build whose ordinal is not above the last it accepted.

## Reporting

Say what was actually done. If a test fails, show the output; if something was
skipped, say so. Do not report work as finished until it is verified — the
commands above are what "verified" means here.
