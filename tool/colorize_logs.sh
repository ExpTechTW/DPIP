#!/usr/bin/env bash
# Colours DPIP's log lines on their way past, in the terminal.
#
# Usage:
#     mise exec -- flutter run | tool/colorize_logs.sh
#
# The app writes plain text on purpose. Colour has to be added *here* rather
# than there, because on iOS it cannot survive the trip: the platform's log
# path escapes the escape character itself, so a terminal that fully supports
# ANSI still receives a backslash followed by the sequence and prints it
# (flutter/flutter#20663). `dart:developer`'s `log` does get escapes through,
# but truncates anything past ~128 characters to `<collected>` — and the long
# lines are the diagnostic ones, so that trade buys colour with the content.
#
# A pipe has neither problem. The bytes are written by this script, in this
# terminal, which is the one place that knows whether ANSI works.
#
# Only the tag is coloured: a fully coloured line is harder to read than a
# plain one, and the tag is what is being scanned for.
set -euo pipefail

# Outlive the thing being coloured.
#
# Ctrl-C goes to every process in the foreground group, so without this the
# filter dies first and `flutter run` — still shutting down, still printing —
# writes into a closed pipe and takes `EPIPE` as an unhandled exception:
#
#     FileSystemException: writeFrom failed (OS Error: Broken pipe, errno = 32)
#         … ResidentRunner._serviceDisconnected
#
# Ignoring the interrupt leaves this reading until its stdin closes, which is
# when the writer has genuinely finished.
trap '' INT

# Off when the output is not a terminal — piped to a file or another program,
# escapes would be exactly the noise this exists to avoid.
if [ -t 1 ]; then
  readonly DIM=$'\033[2m' RESET=$'\033[0m'
  readonly RED=$'\033[31m' YELLOW=$'\033[33m'
  readonly BLUE=$'\033[34m' GREY=$'\033[90m' MAGENTA=$'\033[35m'
else
  readonly DIM='' RESET='' RED='' YELLOW='' BLUE='' GREY='' MAGENTA=''
fi

# `flutter: ` prefixes every line the device prints; dropping it gives back a
# terminal's worth of width, and nothing distinguishes those lines but it.
sed -E \
  -e "s/^flutter: ?//" \
  -e "s/^\[CRITICAL\]/${MAGENTA}[CRITICAL]${RESET}/" \
  -e "s/^\[ERROR\]/${RED}[ERROR]${RESET}/" \
  -e "s/^\[WARN\]/${YELLOW}[WARN]${RESET}/" \
  -e "s/^\[INFO\]/${BLUE}[INFO]${RESET}/" \
  -e "s/^\[DEBUG\]/${GREY}[DEBUG]${RESET}/" \
  -e "s/^\[VERBOSE\]/${GREY}[VERBOSE]${RESET}/" \
  -e "s/\| ([0-9]+:[0-9]{2}:[0-9]{2} [0-9]+ms) \|/| ${DIM}\1${RESET} |/"
