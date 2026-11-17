# Redmine Issue Limits Warning

Redmine plugin that adds visual warnings when an issue approaches or exceeds its estimated time, and when an open issue is past its due date.

## Features

- Global warning and danger thresholds for `spent_hours / estimated_hours`.
- Project-level enable/disable and threshold overrides without a database migration.
- Visual badges on the issue page.
- Issue list highlighting for spent/estimated hours and overdue due dates.
- Project overview summary for time budget and overdue issues.
- Client-side warning while logging time when the new entry reaches or exceeds the estimate threshold.
- English and Bulgarian localization.

## Compatibility

The plugin is designed for Redmine 5.x and 6.x. The initial target environment is Redmine 6.1.x on Ruby 3.2.

## Installation

Copy the plugin directory to:

```text
plugins/redmine_issue_limits_warning
```

Then restart Redmine. The first version does not require plugin migrations.

## Configuration

Global settings are available from Administration -> Plugins -> Redmine Issue Limits Warning -> Configure.

Project settings are available from the project menu entry "Issue limits" for users with the `manage_issue_limits_warning` permission.

## Notes

"Without Estimated Time" includes only open, visible issues in the selected project with no positive estimate and no subtasks. Closed or hidden subtasks, including subtasks in other projects, still make an issue a parent. Subproject issues are not included in the selected project's results.

Version 0.1.0 only visualizes warnings. It does not block time logging. A future version may add role-based blocking when an issue estimate has been exceeded.

## Development tests

The test profile in `.redmine-test.yml` targets Redmine 6.1.2. Tests require a separate Redmine application and its test dependencies; the plugin cannot run independently. The tests use transactional Redmine fixtures and a dedicated test database, never a production database.

With the Codex `redmine-plugin-test-runtime` skill installed, run from the plugin directory in PowerShell:

```powershell
& "$HOME\.codex\skills\redmine-plugin-test-runtime\scripts\setup_redmine_test_runtime.ps1" -SkipBundleInstall
& "$HOME\.codex\skills\redmine-plugin-test-runtime\scripts\run_redmine_plugin_tests.ps1"
```

`-SkipBundleInstall` reuses existing runtime dependencies. For another prepared Redmine checkout, set `REDMINE_ROOT` to its root, link the plugin into its `plugins` directory, and run `ruby bin/rails test plugins/redmine_issue_limits_warning/test/unit/project_issues_filter_test.rb` from that checkout with its test database configured.
