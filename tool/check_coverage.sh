#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

THRESHOLD="${COVERAGE_THRESHOLD:-100}"
RAW_LCOV="coverage/lcov.info"
FILTERED_LCOV="coverage/lcov.filtered.info"

echo "[coverage] Running tests with coverage..."
flutter test --coverage test

if [[ ! -f "$RAW_LCOV" ]]; then
  echo "[coverage] Missing $RAW_LCOV"
  exit 1
fi

# Platform backends and generated bindings need integration/runtime harnesses.
EXCLUDE_REGEX='lib/flutter_kiwi_ffi_bindings_generated\.dart|lib/src/kiwi_analyzer_native\.dart|lib/src/kiwi_analyzer_web\.dart'

awk -v regex="$EXCLUDE_REGEX" '
BEGIN { skip=0 }
/^SF:/ {
  file = substr($0, 4)
  skip = (file ~ regex)
}
!skip { print }
/^end_of_record$/ { skip=0 }
' "$RAW_LCOV" > "$FILTERED_LCOV"

COVERAGE_PERCENT="$(
  awk -F: '
    /^LF:/ { lf += $2 }
    /^LH:/ { lh += $2 }
    END {
      if (lf == 0) {
        print "0.00"
      } else {
        printf "%.2f", (lh / lf) * 100
      }
    }
  ' "$FILTERED_LCOV"
)"

echo "[coverage] Threshold: ${THRESHOLD}%"
echo "[coverage] Result: ${COVERAGE_PERCENT}% (filtered)"
echo "[coverage] Report: $FILTERED_LCOV"

awk -v actual="$COVERAGE_PERCENT" -v threshold="$THRESHOLD" '
BEGIN {
  if ((actual + 0) + 1e-9 < (threshold + 0)) {
    exit 1
  }
}
'

echo "[coverage] PASS"
