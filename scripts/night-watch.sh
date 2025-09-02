#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="logs/night-watch.log"

mkdir -p "$(dirname "$LOG_FILE")"
echo "== Night watch started at $(date -u)" | tee -a "$LOG_FILE"

while true; do
  echo "--- $(date -u) ---" | tee -a "$LOG_FILE"
  # Run your tests quietly; mark GREEN/RED in the log
  npm test --silent && echo "GREEN" | tee -a "$LOG_FILE" || echo "RED" | tee -a "$LOG_FILE"
  sleep 900   # 15 minutes
done
