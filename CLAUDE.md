# CLAUDE.md

**Read [AGENTS.md](AGENTS.md) first.** It is the entry point for anyone working
here — human or agent — and it says which file owns which topic.

This file used to restate the architecture, the design system, the commit rules
and the CI list. All four had a second copy elsewhere, so all four drifted. It
is now a pointer, and the only thing kept here is the short list below: the
rules whose violation is **silent**. Everything else fails loudly enough that a
gate or the analyzer will tell you.

## The ones that fail quietly

- **Log through `Log`, never `print` / `debugPrint`.** (`avoid_print` is an
  analysis error, so this one does fail loudly — it is here because reaching for
  `print` is the reflex.) → [ARCHITECTURE.md § Logging](ARCHITECTURE.md#logging)
- **Every user-facing string goes through `AppLocalizations`.** A hardcoded
  string looks right in Chinese and is invisible in nine other languages.
  → [DESIGN.md § Localization](DESIGN.md#localization)
- **Never hand-write an `IconData` codepoint.** A guessed codepoint is a valid
  `IconData` that silently draws the wrong picture — `rainy` was once
  `0xf07c2`, which is `Icons.severe_cold`, and every rainy hour rendered a
  snowflake. → [DESIGN.md § Icons](DESIGN.md#icons)
- **Settings only through a `SettingKey<T>` from the registry**, never a raw
  string. → [ARCHITECTURE.md § Persistence](ARCHITECTURE.md#persistence)
- **Never `DateTime.now()` for anything a server or a radio timestamps.** Use
  `AppTime`. Two clocks subtracted give an offset, not an age — and a retention
  window computed that way deletes data that is not old.
  → [ARCHITECTURE.md § Calibrated time](ARCHITECTURE.md#calibrated-time)
- **A safety-critical feed that is `stale` or `offline` must never be presented
  as current.** → [ARCHITECTURE.md § Realtime feeds](ARCHITECTURE.md#realtime-feeds)
- **Run tools through `mise exec --`**, or you are testing a different Flutter
  than CI is. A shell's PATH is resolved once and `mise activate` caches it, so
  a toolchain bump leaves the old SDK on PATH until the session is replaced —
  and a build against the wrong SDK announces nothing.
  → [AGENTS.md § Toolchain](AGENTS.md#toolchain)
- **Start the app with `tool/run.sh`** (`tool\run.ps1` on Windows), never
  `flutter run` directly. A debug build refuses to start otherwise — both
  alternatives run, and the difference is the SDK resolved and whether the log
  is readable, neither of which is visible at the time.
  → [AGENTS.md § Running](AGENTS.md#running)
- **No `Co-Authored-By`, no tool attribution, ever.**
  → [AGENTS.md § Commits](AGENTS.md#commits)

## Everything else

| Looking for | Read |
|---|---|
| Folder layout, layer rules, subsystem contracts | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Tokens, colour, spacing, motion, icons, l10n | [DESIGN.md](DESIGN.md) |
| Endpoints and the region map | [api.md](api.md) |
| Commit format | [commit.md](commit.md) |
| Toolchain, running, the pre-push checklist, versions | [AGENTS.md](AGENTS.md) |
