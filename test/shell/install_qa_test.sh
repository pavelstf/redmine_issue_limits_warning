#!/usr/bin/env bash
set -euo pipefail
# The caller supplies a disposable directory and a fixture ZIP containing only init.rb.
root="$(cd -- "$1" && pwd -P)"
archive="$(cd -- "$(dirname -- "$2")" && pwd -P)/$(basename -- "$2")"
installer="$(cd -- "$(dirname -- "$0")/../../scripts" && pwd -P)/install_qa.sh"
mkdir -p "$root/app/bin" "$root/app/plugins/redmine_issue_limits_warning"
touch "$root/app/bin/rails" "$root/app/Gemfile"
printf 'old code\n' > "$root/app/plugins/redmine_issue_limits_warning/init.rb"
checksum="$(sha256sum "$archive" | cut -d' ' -f1)"
assert_no_stage() {
  if compgen -G "$root/app/qa-plugin-stage-*" >/dev/null; then
    echo 'Unexpected staging directory' >&2
    exit 1
  fi
}
for malformed in '' "$checksum"$'\r'; do
  code=0
  output="$(bash "$installer" "$root/app" "$archive" "$malformed" 2>&1)" || code=$?
  test "$code" -eq 2
  [[ "$output" == *'Expected SHA-256 must be 64 hexadecimal characters.'* ]]
done
assert_no_stage
ruby() { return 1; }
export -f ruby
if bash "$installer" "$root/app" "$archive" "$checksum"; then
  echo 'Expected migration failure' >&2; exit 1
fi
grep -q 'old code' "$root/app/plugins/redmine_issue_limits_warning/init.rb"
assert_no_stage
compgen -G "$root/app/qa-plugin-backups/failed-*" >/dev/null
if bash "$installer" "$root/app" "$archive" "$(printf '0%.0s' {1..64})"; then
  echo 'Expected checksum rejection' >&2; exit 1
fi
grep -q 'old code' "$root/app/plugins/redmine_issue_limits_warning/init.rb"
ruby() { return 0; }
export -f ruby
bash "$installer" "$root/app" "$archive" "$checksum"
grep -q 'new code' "$root/app/plugins/redmine_issue_limits_warning/init.rb"
test -f "$root/app/tmp/restart.txt"
assert_no_stage

unzip() {
  if [[ "$1" == '-q' ]]; then
    printf 'partial extraction\n' > "$4/partial.txt"
    return 9
  fi
  command unzip "$@"
}
export -f unzip
code=0
output="$(bash "$installer" "$root/app" "$archive" "$checksum" 2>&1)" || code=$?
test "$code" -eq 9
[[ "$output" == *'Staging directory retained for inspection:'* ]]
grep -q 'partial extraction' "$root"/app/qa-plugin-stage-*/partial.txt
grep -q 'new code' "$root/app/plugins/redmine_issue_limits_warning/init.rb"
echo 'PASS: checksum validation, successful install, code recovery, and staging cleanup/retention.'
