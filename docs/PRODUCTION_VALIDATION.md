# Production Validation

## Release candidate

- Environment: production
- Redmine URL: `https://redmine.gcr.bg`
- Plugin ID: `redmine_issue_limits_warning`
- Plugin version: `0.1.0`
- Package: `redmine_issue_limits_warning-0.1.0-production-20260713.zip`
- Package size: `23516` bytes
- SHA-256: `42E345F7F0214E2D7109B39E50D6CE559CE41B5088BFBF60E56EBF1A6EBABFEA`
- Source commit: `481fd32b82513bf6adccee58de14192f081a0e2e`

## Deployment evidence

- Deployment/validation date: 2026-07-13
- Asset backup file: `/home/gcrbgcaa/redmine/plugins/redmine_issue_limits_warning-public-plugin-assets-backup-20260713-171615.tar.gz`
- Installed version reported from `init.rb`: `0.1.0`
- Validated by: pavel
- Asset repair: successful; production CSS and JavaScript HTTP/content checks passed
- Production log check: completed; the last matching `FATAL` header was at
  `2026-07-13 17:16:07`, before the successful asset repair and UI acceptance.
  No later matching error was reported by the final grep.

## Acceptance checklist

- [x] Administration -> Plugins lists version `0.1.0`.
- [x] Global settings load and save successfully.
- [x] Project-level enable/disable works for a user with `manage_issue_limits_warning`.
- [x] Project threshold overrides work.
- [x] Issue-page time-budget badge shows the correct status and color.
- [x] Overdue open issues show the due-date badge.
- [x] Closed issues do not show warning markers.
- [x] Issue-list warning styles are applied correctly.
- [x] Project overview counts link to visible filtered issue lists.
- [x] "Without Estimated Time" contains only open leaf issues.
- [x] Time-entry warning appears when the entry reaches the danger threshold.
- [x] English and Bulgarian labels render correctly.
- [x] No new plugin-related errors appear after the successful asset repair.

## User confirmation

Status: production validation completed. The UI was accepted by pavel on
2026-07-13 after correcting the Propshaft/public asset layout, and the final log
check reported no matching errors after the repair.
