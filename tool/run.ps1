# `flutter run`, on the pinned toolchain. Windows.
#
#     tool\run.ps1 -d "Pixel 9"
#
# The PowerShell counterpart of tool/run.sh. Every argument is passed through
# untouched.
#
# **It deliberately does not pipe.** The bash script colours the log by piping
# it through tool/internal/colorize_logs.sh, and the same shape here would be wrong:
# `$LASTEXITCODE` is not set reliably when a native command's output goes to a
# cmdlet (PowerShell/PowerShell#19848), so a failed build would exit 0 and this
# wrapper would hide the thing it wraps. That is the one defect a wrapper like
# this must not have, and it is worth more than colour.
#
# For a coloured log on Windows, run the bash script under Git Bash or WSL:
#
#     bash tool/run.sh -d "Pixel 9"
#
# `mise exec --` and not a bare `flutter`: a shell's PATH is resolved once and
# goes stale, while `mise exec` re-reads mise.toml every time.
# See AGENTS.md -> Toolchain.

$ErrorActionPreference = 'Stop'

& mise exec -- flutter run --dart-define=DPIP_RUN_SH=true @args

exit $LASTEXITCODE
