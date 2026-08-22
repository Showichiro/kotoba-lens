#!/usr/bin/env bash
set -euo pipefail

DART="${DART:-dart}"
root="$(cd "$(dirname "$0")/.." && pwd)"

(cd "$root/packages/feature_flag_lifecycle_plugin" && "$DART" pub get && "$DART" test)
(cd "$root/fixtures/feature_flags_valid" && "$DART" pub get && "$DART" analyze)

output="$(cd "$root/fixtures/feature_flags_expired" && "$DART" pub get >/dev/null && "$DART" analyze 2>&1)" && {
  echo 'Expected the expired fixture to fail analysis.' >&2
  exit 1
}

grep -q 'expired_feature_flag' <<<"$output"
grep -q "Feature flag 'oldCheckout' expired on 2000-01-01" <<<"$output"
printf '%s\n' "$output"

