#!/usr/bin/env bash
# The test suite.
#
#     tool/dev/test.sh                    # everything
#     tool/dev/test.sh test/core/logging  # one directory
#
# Arguments are passed straight to `flutter test`.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

pinned flutter test "$@"
