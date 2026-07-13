# Backlog

This backlog records the agreed work order for Redmine Issue Limits Warning.

## Current priorities

- [x] Production deployment and acceptance validation
  - Use `docs/PRODUCTION_RUNBOOK.md` for installation and rollback.
  - Install the approved production package with the production runbook.
  - Verify the global and project settings, issue page, issue list, project overview, and time-entry warning.
  - Verify English and Bulgarian UI and inspect `log/production.log` for new errors.
  - Record the installed version, package SHA-256, backup filename, and user confirmation in `docs/PRODUCTION_VALIDATION.md`.
  - Production UI and the post-repair log check were accepted on 2026-07-13.
- [x] Automated tests implemented (CI confirmation pending)
  - Unit coverage for time-budget and due-date checks.
  - Settings validation and project override coverage.
  - Project issue filter coverage.
  - Controller permission and update coverage.
  - English/Bulgarian locale key and interpolation parity.
- [x] GitHub Actions CI implemented (first GitHub run pending)
  - Ruby syntax and YAML validation.
  - Plugin tests on Redmine 5.1 and 6.1.
  - Production-package structure check.

## Next

- [ ] Validate that the warning threshold is lower than or equal to the danger threshold.
- [ ] Add role-based server-side blocking of time logging after an estimate is reached, with an administrator/manager bypass.
- [ ] Add concise English and Bulgarian help text for non-obvious settings.
- [ ] Measure and optimize project-overview queries for large projects.
- [ ] Evaluate moving project settings from the global plugin setting hash to a dedicated table.
- [ ] Audit accessibility, color contrast, responsive layout, and theme compatibility.
