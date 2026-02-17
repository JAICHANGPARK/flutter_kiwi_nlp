#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: verify_plugin.sh [options]

Runs common validation commands for flutter_kiwi_nlp.

Options:
  --no-pub-get       Skip dependency resolution
  --no-analyze       Skip flutter analyze
  --no-test          Skip flutter test in plugin root
  --no-example-test  Skip flutter test in example/
  -h, --help         Show help
EOF
}

run_pub_get=1
run_analyze=1
run_test=1
run_example_test=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pub-get)
      run_pub_get=0
      shift
      ;;
    --no-analyze)
      run_analyze=0
      shift
      ;;
    --no-test)
      run_test=0
      shift
      ;;
    --no-example-test)
      run_example_test=0
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../.." && pwd)"

run_cmd() {
  echo "+ $*"
  "$@"
}

cd "${repo_root}"

if [[ "${run_pub_get}" -eq 1 ]]; then
  run_cmd flutter pub get
  (
    cd example
    run_cmd flutter pub get
  )
fi

if [[ "${run_analyze}" -eq 1 ]]; then
  run_cmd flutter analyze
fi

if [[ "${run_test}" -eq 1 ]]; then
  run_cmd flutter test
fi

if [[ "${run_example_test}" -eq 1 ]]; then
  (
    cd example
    run_cmd flutter test
  )
fi

echo "verify_plugin.sh completed successfully."
