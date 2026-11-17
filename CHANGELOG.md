# Changelog

## Unreleased

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
