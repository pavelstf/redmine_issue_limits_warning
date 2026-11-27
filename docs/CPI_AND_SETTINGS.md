# CPI and project settings

## Behaviour

This revision uses labour efficiency, not financial CPI: `estimated_hours × issue.done_ratio / 100 ÷ spent_hours`. Redmine's effective `done_ratio` is used, including status-based progress. Only structural leaf issues have CPI/absolute-budget evaluation; overdue checks still apply to all visible open issues. Closed issues have no warnings. SPI and project-level EVM are outside scope.

- CPI >= 0.90: OK; 0.80 <= CPI < 0.90: warning; CPI < 0.80: danger.
- Positive estimate and positive spent hours are required. Missing estimate or no recorded hours is unavailable, never green. Recorded hours at zero progress give CPI zero and a specific explanation.
- Forecast hours = spent hours / progress fraction; no forecast at zero progress. Below 10% progress, forecasts are marked preliminary. Forecasts assume current efficiency continues and do not account for remaining-work complexity.
- Independent absolute limit is disabled by default. When enabled, consumed budget >= the configured percentage produces a danger signal even when CPI is OK. Values above 100% are supported. Both CPI and absolute-limit reasons are displayed; old 80/100 consumption thresholds are not converted into CPI thresholds.
- Disabling the project module or the project enabled flag suppresses all warning surfaces and denies direct list/context URLs. The module must be enabled explicitly; installing the update does not enable it for existing projects.
- Project counts/lists use only visible open direct project issues. Missing-estimate leaves have their own category; positive-estimate leaves without a calculable CPI use the unavailable category. Overdue may overlap other categories. The filtered list defaults to descending issue ID. Click CPI or % Done to sort all matching issues before pagination. Unavailable CPI appears last in both directions, and ties use descending issue ID.
- CPI has no approved frozen budget baseline in this plugin. Editing the estimate or progress changes the current assessment. This is an operational indicator, not historical EVM accounting.

## Settings storage and validation

Global defaults remain in `Setting.plugin_redmine_issue_limits_warning`. Project overrides are in `rilw_project_settings`, one uniquely indexed row per project, with decimal CPI/limit values, boolean flags and optimistic `lock_version`. A foreign key removes rows when their project is deleted. Different projects no longer share a read-modify-write hash. Stale edits to an existing row return HTTP 409 and reload current values. Validation rejects malformed/non-finite numbers, 0 >= critical, critical > warning, warning > 1, and absolute percentages outside (0,999]. Global colors must be #RRGGBB.

The standard Redmine global plugin POST is intercepted only for this plugin, retaining core authorization/CSRF callbacks. Other plugin settings actions retain core behaviour. This narrow extension is necessary to return validation errors before Redmine's native hash replacement.

Project overrides apply CPI and absolute-limit settings together when enabled. The due-date flag is a project-specific setting when a row exists. Display switches and colors are global.

Open **Project → Settings → Issue limits**. With the project module enabled, Redmine administrators and project roles with **Edit project** can view and save the settings. The tab remains available when warnings are switched off in the plugin form so the same users can re-enable them. Disabling the project module hides the tab and blocks direct writes.

## Migration and rollback

Back up the database and existing plugin directory when upgrading from the original v0.1.0 or another installation with pending plugin migrations. From the Redmine root, run the plugin migrations, refresh assets and restart the application:

```bash
# Run with the target Redmine instance's Ruby environment active.
RAILS_ENV=production ruby bin/rails redmine:plugins:migrate NAME=redmine_issue_limits_warning
RAILS_ENV=production ruby bin/rails assets:precompile
touch tmp/restart.txt
```

The migration copies legacy project enable/override/due-date settings. CPI starts at 0.90/0.80. A valid legacy danger percentage is retained as an inactive absolute limit. Legacy project hashes remain untouched as rollback evidence. Missing projects are skipped; existing new rows are not overwritten on repeat execution. Settings already deleted by an earlier global save can only be recovered from a backup.

Migration 001 creates the table as InnoDB on MySQL/MariaDB. Migration 002 checks the engine and cascading foreign key, repairs MyISAM tables, and leaves an already correct table intact. On SQLite, migration 002 makes no schema changes. Both migrations preserve project settings.

r4 and r5 share the same schema and assets. Update or roll back between them by replacing the plugin code and restarting Redmine. Keep the InnoDB table, its foreign key and both migration records. When rolling back to pre-CPI code, the old plugin reads its legacy settings hash. A separately verified export is needed if the old code must use settings created or changed in the CPI table.

`scripts/install_qa.sh` stages/verifies the archive before replacing code, saves the old directory outside plugins, and attempts code/asset recovery on failure. It does not reverse database migrations. Use only an isolated QA root and a pre-existing QA database backup. For a non-Passenger server, restart its QA service explicitly.

## Tests

See the [development test commands](../README.md#development-tests) for a prepared Redmine 6.1.2 checkout with an isolated test database.

Batch evaluation preloads issue status/project/modules, loads project settings together, and computes direct issue spent hours with a grouped SUM. There is no user-independent cross-request cache. Tests compare SQL counts for 50, 500 and 5000 synthetic leaf issues. Large-project staging request time and memory still require environment-specific measurement.
