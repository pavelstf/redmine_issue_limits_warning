#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 3 ]; then
  echo 'Usage: bash install_qa.sh /isolated/qa-redmine /path/plugin.zip EXPECTED_SHA256' >&2
  exit 2
fi
qa_root="$(cd -- "$1" && pwd -P)"
archive="$(cd -- "$(dirname -- "$2")" && pwd -P)/$(basename -- "$2")"
expected="$3"
if [[ ! "$expected" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo 'Expected SHA-256 must be 64 hexadecimal characters.' >&2
  exit 2
fi
test -f "$qa_root/bin/rails"
test -f "$qa_root/Gemfile"
test -d "$qa_root/plugins"
printf '%s  %s\n' "$expected" "$archive" | sha256sum -c -
plugin=redmine_issue_limits_warning
target="$qa_root/plugins/$plugin"
test ! -L "$target"
if unzip -Z1 "$archive" | grep -Ev '^redmine_issue_limits_warning/([^/]+/)*[^/]*$'; then
  echo 'Unexpected archive root' >&2; exit 1
fi
if unzip -Z1 "$archive" | grep -E '(^|/)(\.\.|\.git)(/|$)|\\'; then
  echo 'Unsafe archive path' >&2; exit 1
fi
stamp="$(date -u +%Y%m%dT%H%M%SZ)-$$"
backup_root="$qa_root/qa-plugin-backups"
mkdir -p -- "$backup_root"
stage="$(mktemp -d "$qa_root/qa-plugin-stage-XXXXXXXX")"
backup="$backup_root/$plugin-$stamp"
replaced=0
had_previous=0
recover() {
  code=$?
  trap - EXIT
  if ! rmdir -- "$stage" 2>/dev/null; then
    printf 'Staging directory retained for inspection: %s\n' "$stage" >&2
  fi
  if [ "$code" -ne 0 ] && [ "$replaced" -eq 1 ]; then
    if [ -e "$target" ]; then mv -- "$target" "$backup_root/failed-$plugin-$stamp"; fi
    if [ "$had_previous" -eq 1 ]; then
      mv -- "$backup" "$target"
      (cd -- "$qa_root" && RAILS_ENV=production ruby bin/rails assets:precompile) || echo 'Rebuilding restored assets failed; manual intervention required.' >&2
    fi
    mkdir -p -- "$qa_root/tmp"
    touch "$qa_root/tmp/restart.txt"
    echo 'Code restored. Database migrations were not reversed; restore the QA DB backup if needed.' >&2
  fi
  exit "$code"
}
trap recover EXIT
unzip -q "$archive" -d "$stage"
test -f "$stage/$plugin/init.rb"
if [ -e "$target" ]; then
  test -d "$target"
  mv -- "$target" "$backup"
  had_previous=1
fi
replaced=1
mv -- "$stage/$plugin" "$target"
cd -- "$qa_root"
RAILS_ENV=production ruby bin/rails redmine:plugins:migrate NAME=redmine_issue_limits_warning
RAILS_ENV=production ruby bin/rails runner 'puts Redmine::Plugin.find(:redmine_issue_limits_warning).version'
RAILS_ENV=production ruby bin/rails assets:precompile
mkdir -p tmp
touch tmp/restart.txt
echo "QA install complete. Previous code: $backup (if previously installed)."
echo 'Restart the QA service explicitly when not using Passenger.'
