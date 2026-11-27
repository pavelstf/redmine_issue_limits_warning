# Changelog

## CPI revision r8 — 2026-11-27

- Sort the filtered issue list by CPI or completion before pagination. Keep unavailable CPI values last in both directions.
- Show the planned due date and calendar days overdue in the tooltip in the standard and filtered issue lists.

## CPI revision r5 — 2026-11-27

- Show completion, logged and estimated hours, and the reason for a CPI warning in both issue lists. When reached, show the configured absolute limit in the tooltip.

- Move project-level Issue limits into the standard project Settings tabs and use Redmine's Edit project permission for viewing and saving.

- Use InnoDB for project settings on MySQL/MariaDB and repair older MyISAM installations with migration 002.

- Show CPI reasons and overdue hints on issue list markers. Green CPI markers can be enabled in global settings and are hidden by default.

- Address CPI QA r1 findings: Linux checksum handling and staging cleanup, grouped hours in filtered lists, Redmine duration edge cases, and consistent first-save conflict responses.

- Replace consumed-percentage alarms with progress-aware CPI (0.90/0.80), unavailable-data states and forecasts; keep an independent optional absolute limit, including values above 100%. SPI is excluded.
- Add project settings table, non-destructive legacy import, optimistic locking and server-side global/project validation.
- Fix settings route collision, module disablement, duration parsing, time-entry edit baselines and dynamic issue selection with permission-checked context.
- Batch settings/status/spent-hour evaluation; apply configured colors and filtered-list highlighting.
- Add controller, settings, migration, performance and JavaScript regression coverage, plus a QA installer with staged extraction and code recovery.
- Count only structural leaf issues in "Without Estimated Time", excluding parents even when their subtasks are closed, hidden, or in another project.
- Add Redmine 6.1.2 regression tests for missing-estimate filtering, visibility, and summary/list parity.
- Correct GitHub metadata links and exclude local handoff and SQLite test database files from Git.

## 0.1.0

- Initial development version.
- Added time budget warnings based on spent time versus estimated time.
- Added overdue due date warning for open issues.
- Added global and project-level settings.
- Added issue page, issue list, project overview, and time entry warning surfaces.
- Fixed hook partial local variable access for Redmine 6.1.x.
- Removed issue hook dependency on plugin helper methods.
- Disabled visual markers for closed issues and adjusted issue list due date spacing.
- Added linked project overview counts that open filtered visible issue lists.
- Changed "Without Estimated Time" to include only leaf issues.
