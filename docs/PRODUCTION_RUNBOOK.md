# Production Installation Runbook

## Target

- Environment: production
- Redmine root: `/home/gcrbgcaa/redmine`
- Redmine URL: `https://redmine.gcr.bg`
- Ruby virtualenv: `/home/gcrbgcaa/rubyvenv/redmine612build/3.2`
- Plugin folder and ID: `redmine_issue_limits_warning`

## ZIP file

- Filename: `redmine_issue_limits_warning-0.1.0-production-20260713.zip`
- Expected version: `0.1.0`
- Size: `23516` bytes
- SHA-256: `42E345F7F0214E2D7109B39E50D6CE559CE41B5088BFBF60E56EBF1A6EBABFEA`

Upload the unchanged ZIP to:

```text
/home/gcrbgcaa/redmine/plugins/redmine_issue_limits_warning-0.1.0-production-20260713.zip
```

## Install or update

Paste the complete block into cPanel Terminal:

```bash
clear
set -eo pipefail

TARGET_ENV="production"
PLUGIN_NAME="redmine_issue_limits_warning"
PLUGIN_ID="redmine_issue_limits_warning"
ZIP_FILE="redmine_issue_limits_warning-0.1.0-production-20260713.zip"
EXPECTED_VERSION="0.1.0"
EXPECTED_SHA256="42E345F7F0214E2D7109B39E50D6CE559CE41B5088BFBF60E56EBF1A6EBABFEA"

REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"
UPLOAD_DIR="$REDMINE_ROOT/plugins"
BACKUP_DIR="$REDMINE_ROOT/plugins"
STAMP="$(date +%Y%m%d-%H%M%S)"
TMP_DIR="/tmp/${PLUGIN_NAME}-${STAMP}"

echo "== Activating Ruby virtualenv =="
source "$VENV_PATH/bin/activate"
set -u

echo "== Checking uploaded ZIP =="
test -f "$UPLOAD_DIR/$ZIP_FILE"
ACTUAL_SHA256="$(sha256sum "$UPLOAD_DIR/$ZIP_FILE" | awk '{print toupper($1)}')"
echo "Expected SHA-256: $EXPECTED_SHA256"
echo "Actual SHA-256:   $ACTUAL_SHA256"
test "$ACTUAL_SHA256" = "$EXPECTED_SHA256"

echo "== Extracting and validating package =="
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
unzip -q "$UPLOAD_DIR/$ZIP_FILE" -d "$TMP_DIR"
test -f "$TMP_DIR/$PLUGIN_NAME/init.rb"
grep -n "version" "$TMP_DIR/$PLUGIN_NAME/init.rb"
grep -q "version '0.1.0'" "$TMP_DIR/$PLUGIN_NAME/init.rb"

echo "== Current installed version, if any =="
if [ -f "$REDMINE_ROOT/plugins/$PLUGIN_NAME/init.rb" ]; then
  grep -n "version" "$REDMINE_ROOT/plugins/$PLUGIN_NAME/init.rb" || true
else
  echo "Plugin is not currently installed."
fi

echo "== Creating backup if plugin exists =="
if [ -d "$REDMINE_ROOT/plugins/$PLUGIN_NAME" ]; then
  BACKUP_FILE="$BACKUP_DIR/${PLUGIN_NAME}-${TARGET_ENV}-backup-${STAMP}.tar.gz"
  tar -czf "$BACKUP_FILE" -C "$REDMINE_ROOT/plugins" "$PLUGIN_NAME"
  echo "BACKUP_FILE=$BACKUP_FILE"
else
  echo "First installation: no existing plugin directory to back up."
fi

echo "== Installing plugin =="
rm -rf "$REDMINE_ROOT/plugins/$PLUGIN_NAME"
cp -a "$TMP_DIR/$PLUGIN_NAME" "$REDMINE_ROOT/plugins/$PLUGIN_NAME"

echo "== Running plugin migration task =="
cd "$REDMINE_ROOT"
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

echo "== Copying plugin assets =="
mkdir -p "public/assets/plugin_assets/$PLUGIN_NAME"
cp -a \
  "plugins/$PLUGIN_NAME/assets/stylesheets/redmine_issue_limits_warning.css" \
  "public/assets/plugin_assets/$PLUGIN_NAME/redmine_issue_limits_warning.css"
cp -a \
  "plugins/$PLUGIN_NAME/assets/javascripts/redmine_issue_limits_warning.js" \
  "public/assets/plugin_assets/$PLUGIN_NAME/redmine_issue_limits_warning.js"

# Retain the conventional Redmine plugin asset layout as a fallback.
mkdir -p "public/plugin_assets/$PLUGIN_NAME/stylesheets"
cp -a "plugins/$PLUGIN_NAME/assets/stylesheets/." \
  "public/plugin_assets/$PLUGIN_NAME/stylesheets/"
mkdir -p "public/plugin_assets/$PLUGIN_NAME/javascripts"
cp -a "plugins/$PLUGIN_NAME/assets/javascripts/." \
  "public/plugin_assets/$PLUGIN_NAME/javascripts/"

echo "== Restarting Redmine via Passenger =="
touch tmp/restart.txt

echo "== Verifying installed files and version =="
test -f "plugins/$PLUGIN_NAME/init.rb"
test -f "public/assets/plugin_assets/$PLUGIN_NAME/redmine_issue_limits_warning.css"
test -f "public/assets/plugin_assets/$PLUGIN_NAME/redmine_issue_limits_warning.js"

INSTALLED_VERSION="$(
  RAILS_ENV=production bundle exec rails runner \
    "puts Redmine::Plugin.find(:$PLUGIN_ID).version" | tail -n 1
)"
echo "Expected version:  $EXPECTED_VERSION"
echo "Installed version: $INSTALLED_VERSION"
test "$INSTALLED_VERSION" = "$EXPECTED_VERSION"

echo "== Recent error check =="
grep -n -E \
  "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" \
  log/production.log | tail -n 80 || true

echo "== Installation completed successfully =="
echo "Plugin:  $PLUGIN_ID"
echo "Version: $INSTALLED_VERSION"
```

The plugin currently has no database migrations. The standard migration task is retained as a safe deployment check.

## Rollback from backup

Use the exact `BACKUP_FILE=...` printed by the installation block:

```bash
clear
set -eo pipefail

PLUGIN_NAME="redmine_issue_limits_warning"
PLUGIN_ID="redmine_issue_limits_warning"
REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"

# Replace this value with the exact backup path printed during installation.
BACKUP_FILE="/home/gcrbgcaa/redmine/plugins/redmine_issue_limits_warning-production-backup-YYYYMMDD-HHMMSS.tar.gz"

source "$VENV_PATH/bin/activate"
set -u
test -f "$BACKUP_FILE"

cd "$REDMINE_ROOT"
rm -rf "plugins/$PLUGIN_NAME"
tar -xzf "$BACKUP_FILE" -C plugins
test -f "plugins/$PLUGIN_NAME/init.rb"

bundle exec rake redmine:plugins:migrate RAILS_ENV=production

rm -rf "public/plugin_assets/$PLUGIN_NAME"
rm -rf "public/assets/plugin_assets/$PLUGIN_NAME"
if [ -d "plugins/$PLUGIN_NAME/assets/stylesheets" ]; then
  mkdir -p "public/assets/plugin_assets/$PLUGIN_NAME"
  cp -a \
    "plugins/$PLUGIN_NAME/assets/stylesheets/redmine_issue_limits_warning.css" \
    "public/assets/plugin_assets/$PLUGIN_NAME/redmine_issue_limits_warning.css"
  mkdir -p "public/plugin_assets/$PLUGIN_NAME/stylesheets"
  cp -a "plugins/$PLUGIN_NAME/assets/stylesheets/." \
    "public/plugin_assets/$PLUGIN_NAME/stylesheets/"
fi
if [ -d "plugins/$PLUGIN_NAME/assets/javascripts" ]; then
  mkdir -p "public/assets/plugin_assets/$PLUGIN_NAME"
  cp -a \
    "plugins/$PLUGIN_NAME/assets/javascripts/redmine_issue_limits_warning.js" \
    "public/assets/plugin_assets/$PLUGIN_NAME/redmine_issue_limits_warning.js"
  mkdir -p "public/plugin_assets/$PLUGIN_NAME/javascripts"
  cp -a "plugins/$PLUGIN_NAME/assets/javascripts/." \
    "public/plugin_assets/$PLUGIN_NAME/javascripts/"
fi

touch tmp/restart.txt
grep -n "version" "plugins/$PLUGIN_NAME/init.rb"
RAILS_ENV=production bundle exec rails runner \
  "puts Redmine::Plugin.find(:$PLUGIN_ID).version"
grep -n -E \
  "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" \
  log/production.log | tail -n 80 || true
```

## Rollback after a first installation

Use only when there was no previous plugin installation and therefore no backup:

```bash
clear
set -eo pipefail

PLUGIN_NAME="redmine_issue_limits_warning"
REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"

source "$VENV_PATH/bin/activate"
set -u
cd "$REDMINE_ROOT"

rm -rf "plugins/$PLUGIN_NAME"
rm -rf "public/plugin_assets/$PLUGIN_NAME"
rm -rf "public/assets/plugin_assets/$PLUGIN_NAME"
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch tmp/restart.txt
echo "Plugin removed and Passenger restarted."
```

## Manual validation checklist

Record the results in `docs/PRODUCTION_VALIDATION.md`.

- [ ] Administration -> Plugins lists version `0.1.0`.
- [ ] Global settings load and save successfully.
- [ ] Project enable/disable and threshold overrides work.
- [ ] Time-budget and overdue badges render correctly.
- [ ] Closed issues do not show warning markers.
- [ ] Issue-list styles and project-overview links work.
- [ ] "Without Estimated Time" contains only open leaf issues.
- [ ] Time-entry warning appears at the danger threshold.
- [ ] English and Bulgarian labels render correctly.
- [ ] No new plugin-related errors appear in `log/production.log`.

## Dependencies

This release has no external plugin or provider API dependencies.
