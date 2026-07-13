# Session Handoff

Last updated: 2026-07-13

## Start here

Repository: `pavelstf/redmine_issue_limits_warning`

Work branch: `agent/production-handover-ci-tests`

On another machine:

```bash
git clone https://github.com/pavelstf/redmine_issue_limits_warning.git
cd redmine_issue_limits_warning
git fetch origin
git switch agent/production-handover-ci-tests
```

Review this file, `docs/BACKLOG.md`, `docs/PRODUCTION_VALIDATION.md`, and
`docs/PRODUCTION_RUNBOOK.md` before continuing.

## Production state

- Environment: GCR production
- URL: `https://redmine.gcr.bg`
- Redmine root: `/home/gcrbgcaa/redmine`
- Ruby virtualenv: `/home/gcrbgcaa/rubyvenv/redmine612build/3.2`
- Plugin ID/folder: `redmine_issue_limits_warning`
- Installed version: `0.1.0`
- Production UI acceptance: confirmed by pavel on 2026-07-13
- Production log acceptance: confirmed; no matching errors were reported after
  the successful asset repair

Production package:

- File: `redmine_issue_limits_warning-0.1.0-production-20260713.zip`
- Size: `23516` bytes
- SHA-256: `42E345F7F0214E2D7109B39E50D6CE559CE41B5088BFBF60E56EBF1A6EBABFEA`
- Source commit: `481fd32b82513bf6adccee58de14192f081a0e2e`
- Archive root: `redmine_issue_limits_warning/`

Asset repair:

- Redmine generated URLs under `/assets/plugin_assets/redmine_issue_limits_warning/`.
- The original deployment copied assets only to the conventional nested
  `public/plugin_assets/.../{stylesheets,javascripts}` layout, so CSS and JS
  returned HTTP 404 and issue-list markers were absent.
- Production was repaired by copying the CSS and JavaScript directly into:
  `/home/gcrbgcaa/redmine/public/assets/plugin_assets/redmine_issue_limits_warning/`.
- HTTP/content checks completed successfully and the full interface was accepted.
- Recorded asset backup:
  `/home/gcrbgcaa/redmine/plugins/redmine_issue_limits_warning-public-plugin-assets-backup-20260713-171615.tar.gz`
- `docs/PRODUCTION_RUNBOOK.md` now contains the corrected layout.

## Work completed in this branch

- Added the agreed backlog and production validation evidence.
- Added the corrected production install/update and rollback runbook.
- Added unit tests for time-budget, due-date, settings, filters, and locale parity.
- Added functional controller tests for project settings and filtered issue lists.
- Added GitHub Actions CI with:
  - Ruby syntax validation;
  - EN/BG YAML key and interpolation-placeholder parity;
  - production archive structure checks;
  - Redmine `5.1-stable` with Ruby 3.2;
  - Redmine `6.1-stable` with Ruby 3.2.
- Added testing instructions to `README.md`.

## Validation evidence and limitations

Passed locally:

- Ruby syntax for plugin and test files;
- YAML parsing for locales and workflow;
- EN/BG locale key parity;
- EN/BG interpolation-placeholder parity;
- `git diff --check`.

Not completed locally:

- The full Redmine test suite could not finish on the Windows workstation
  because native Ruby gems required an unavailable MSYS2 build toolchain.
- The GitHub Actions workflow is intended to provide the authoritative Linux
  integration result after the branch is pushed.

## Agreed task status

1. Production deployment and acceptance validation: complete.
2. Automated test implementation: complete; GitHub CI confirmation pending.
3. GitHub Actions CI implementation: complete; first run pending.

## Next actions

1. Inspect the draft PR checks and fix any Redmine 5.1/6.1 test failures.
2. When CI is green, review and merge the draft PR into `main`.
3. Continue with the next backlog item: validate that the warning threshold is
   less than or equal to the danger threshold, with EN/BG administrator feedback.
4. After that, design role-based server-side blocking of time logging.

## Safety notes

- Do not deploy directly from Codex; produce manual GCR runbooks for the user.
- Preserve the special production Ruby virtualenv path
  `/home/gcrbgcaa/rubyvenv/redmine612build/3.2`.
- Keep production ZIPs and plugin code backups in the target Redmine `plugins/`
  directory.
- Restart Passenger with `touch tmp/restart.txt`.
- The production ZIP is intentionally ignored by Git. If it is published to
  GitHub, attach the unchanged bytes to the existing `v0.1.0` release and verify
  the SHA-256 before and after upload.
