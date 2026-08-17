// GENERATED — do not edit by hand. Written by tool/gen_build_info.sh (run by the
// git hooks in .githooks/; set up once with tool/setup.sh). Holds what git knows
// about this build, so a debug build can name itself without CI's --dart-define.
//
// What is *committed* here is a stub, on purpose. The file is `skip-worktree`
// locally so a regenerated copy never dirties the tree — which also means a
// real value written here would be frozen at whoever last cleared that flag,
// and a clone that has not run tool/setup.sh would confidently report someone
// else's build. Empty values fall back to the platform's own version instead.
library;

/// Short git commit hash of HEAD at generation time ('unknown' outside a repo).
const String kGitCommit = 'unknown';

/// The label tool/version.sh derives for HEAD — '26w33b', '26.1'. Empty when
/// git could not answer, in which case the platform's own version is used.
const String kBuildLabel = '';

/// The ordinal that goes with it; 0 when git could not answer.
const int kBuildCode = 0;

/// The newest release tag this history knows, 'v' stripped. Empty until
/// tool/version.sh can read the history; the version card falls back to the
/// label then.
const String kLastRelease = '';