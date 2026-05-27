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

Version 0.1.0 only visualizes warnings. It does not block time logging. A future version may add role-based blocking when an issue estimate has been exceeded.
