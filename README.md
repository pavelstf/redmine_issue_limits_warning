# Redmine Issue Limits Warning

Redmine plugin that visualizes issue labour efficiency (CPI in hours), optional absolute budget limits, and overdue open issues.

## Features

- Progress-aware CPI: `estimated_hours × done_ratio / 100 ÷ spent_hours`, with warning below 0.90 and danger below 0.80.
- Optional independent absolute budget percentage, including limits above 100%.
- Project-level enable/disable and threshold overrides stored in a dedicated table with optimistic locking.
- Visual badges on the issue page.
- Issue list highlighting for spent/estimated hours and overdue due dates.
- Project overview summary for time budget and overdue issues.
- Client-side warning while logging time when the new entry would trigger a CPI warning or reach the configured absolute limit.
- English and Bulgarian localization.

## Compatibility

The CPI revision r5 was verified on Redmine 6.1.2 with Ruby 3.2 in production. Local regression tests also ran on Ruby 3.3.

## Installation

Copy the plugin directory to:

```text
plugins/redmine_issue_limits_warning
```

When upgrading from the original v0.1.0 or another installation with pending plugin migrations, run those migrations before refreshing assets and restarting Redmine. Updating from r4 to r5 reuses the r4 schema and compiled assets. See [CPI, migration, rollback and test instructions](docs/CPI_AND_SETTINGS.md).

See [QA remediation and validation evidence](docs/QA_REMEDIATION.md) for the fixes and acceptance results.

## Configuration

Global settings are available from Administration -> Plugins -> Redmine Issue Limits Warning -> Configure.

Hover over a marker in the standard or filtered issue list for CPI, completion, logged and estimated hours, and the warning reason. The tooltip includes the absolute threshold when reached. Totals in the tooltip follow Redmine time-entry visibility. Hover over a marked due date for the overdue hint. Green CPI markers are hidden by default and can be enabled in global settings.

When the Issue limits module is enabled, open **Project → Settings → Issue limits**. Administrators and users with Redmine's **Edit project** permission for that project can view and save these settings.

## Notes

"Without Estimated Time" includes only open, visible issues in the selected project with no positive estimate and no subtasks. Closed or hidden subtasks, including subtasks in other projects, still make an issue a parent. Subproject issues are not included in the selected project's results.

Warnings never block time logging. Disabling the project module disables all functionality. CPI applies to structural leaves and uses the standard Redmine Done ratio. Unavailable CPI is not labelled OK. SPI is outside scope.

## Development tests

The test profile in `.redmine-test.yml` targets Redmine 6.1.2. Tests require a separate Redmine application and its test dependencies; the plugin cannot run independently. The tests use transactional Redmine fixtures and a dedicated test database, never a production database.

Copy or link the plugin into the `plugins` directory of the test checkout. From the Redmine root, with a dedicated test database configured, run:

```bash
RAILS_ENV=test ruby bin/rails db:migrate
RAILS_ENV=test ruby bin/rails redmine:plugins:migrate NAME=redmine_issue_limits_warning
RAILS_ENV=test ruby bin/rails test plugins/redmine_issue_limits_warning/test
node --test plugins/redmine_issue_limits_warning/test/javascript/time_entry_test.js
```
