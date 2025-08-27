#!/usr/bin/env bash
# Keeps the Mac awake for N hours (default 10h) to prevent sleep/display sleep.
# Usage: ./scripts/keep_awake_overnight.sh [hours]
HOURS="${1:-10}"
SECS=$(( HORS=HOURS, HOURS*3600 ))   # shellcheck disable=SC2034
SECS=$(( HOURS * 3600 ))
echo "[KaizenEdge] Keeping system awake for ${HOURS}h..."
# -d (no display sleep), -i (no idle sleep), -s (no system sleep on AC), -u (assert user active)
# -t <seconds> sets a timeout; "&" pushes it to background.
nohup caffeinate -disu -t "${SECS}" >/tmp/kaizenedge_caffeinate.log 2>&1 &
echo $! > /tmp/kaizenedge_caffeinate.pid
echo "[KaizenEdge] caffeinate PID $(cat /tmp/kaizenedge_caffeinate.pid). Log: /tmp/kaizenedge_caffeinate.log"
