#!/usr/bin/env bash
# Start gdbserver on remote, then connect to it via local gdb
PID="$1"
# Start gdbserver on the remote (no sudo if running as same user, or use ssh to root)
ssh -4 -p 22220 alex@localhost \
  "sudo -S /usr/lib/cargo/bin/sudo gdbserver localhost:1234 --attach ${PID}" </dev/null