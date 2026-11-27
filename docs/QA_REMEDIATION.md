# QA remediation — CPI revision

The independent QA report from 2026-11-25 informed the CPI revision. The findings below describe the initial remediation and its verification. See the r5 acceptance results at the end.

## Agreed scope

- CPI in hours, using native Redmine Done ratio: warning below 0.90, danger below 0.80.
- Independent optional absolute budget limit, disabled by default and supporting values above 100%.
- Structural leaf evaluation for CPI/absolute limits. Due-date warnings remain independent.
- Project module disables all plugin functionality. No SPI or project-level EVM.
- Dedicated per-project settings table with non-destructive legacy import and optimistic locking.

## Findings and resolution

| Finding | Resolution | Verification |
| --- | --- | --- |
| ILW-01 routes | Settings resource before category route; category constraints include only supported states. | Routing tests; edit/save/redirect controller test; real browser save returned to edit successfully. |
| ILW-02 overrides lost | Project rows independent of global settings hash. Native global POST is scoped/validated only for this plugin. Old hash retained for rollback evidence. | Real SettingsController POST preserves row; validation failure preserves stored global values. |
| ILW-03 duration | Parser matches documented Redmine decimal/h:mm/hours/minute formats, rejecting partial strings. | Node cases for decimal dot/comma, 1:30, 1h30, 1h, 90m, 2 hours and invalid inputs. |
| ILW-04 edit hours | Read original persisted entry hours server-side and subtract only for its original issue. | Controller tests for create/edit/issue move; JS baseline test; real browser edit 80h to 50h clears false warning without saving. |
| ILW-05 >100% threshold | Old raw consumption model superseded by agreed CPI model; absolute threshold is independent and can exceed 100%. | Ruby/JS boundary and 120% limit tests. |
| ILW-06 performance | Batch issue/status/project/module loads, grouped spent-hour SUM, settings per project per batch; no cross-user result cache. | SQL regression at 50/500/5000 added issues; staging memory/request measurements remain pending. |
| ILW-07 module | Settings enabled check includes module; lists/context deny direct disabled access; issue and overview hooks suppress output. | Controller, filter and actual issue/overview rendering tests. |
| ILW-08 dynamic issue | Context endpoint checks visibility, log-time and entry edit permissions; clear on change/error, ignore stale responses. Handle native input/change, project change and Redmine jQuery autocomplete. | Native/jQuery Node tests; real browser jQuery clear → hidden, selection → recalculated warning. |
| ILW-09 colors | OK list cells and overview dots use configured colors; time-entry border/background use semantic configured color. Closed theme styles are no longer explicitly reset. | Hook color rendering test and real browser list marker inspection. Other customer themes remain to be checked. |
| ILW-10 custom list | Explicit shared status partial, reused evaluation data, CPI/progress columns, left-aligned subject and internal horizontal scrolling. | Controller rendering/escaping test; desktop/mobile browser smoke, 4px marker, 0px whole-page overflow at 360px. Column sorting remains deferred as a separate enhancement. |
| ILW-11 validation | Finite numeric input, ordered CPI thresholds, absolute range and global color validation; localized error responses. | Global/model/controller invalid-input tests; comma decimal normalization test. |
| ILW-12 concurrent writes | Separate rows for different projects; unique project index, optimistic locking for existing rows, first-form token for initially absent rows. | Independent-row saves, stale-row and two-first-forms regression tests. Concurrency tests use deterministic interleaving rather than a DB-specific threaded load test. |
| ILW-13 installer recovery | New scripts/install_qa.sh validates/stages before swap, backs up outside plugins, restores code on failure and attempts restored assets. DB migration rollback remains explicit/manual. | Shell fixture tests: failed migration restores old code; checksum mismatch leaves it intact; successful install signals restart. Original historical QA ZIP remains unchanged. |

## Local validation, 2026-11-25

- Redmine 6.1.2 / Rails 7.2.3 / Ruby 3.3.11 / dedicated SQLite test database.
- Full Ruby suite: **42 runs, 231 assertions, 0 failures, 0 errors, 0 skips**, seed 58123.
- Node suite: **6 tests passed**, zero failures/skips. Includes stale-response and native/jQuery dynamic-selection cases.
- Installer: bash syntax and three disposable-fixture recovery scenarios passed. No real deployment was executed by this script.
- Actual SQL SELECT counts (fixture issues plus the stated synthetic volume): 50 added issues → 11; 500 → 15; 5000 → 78. Measured filter evaluation times: 0.212s / 0.088s / 1.131s. Timings reflect local warm-up/cache effects, not a production benchmark; dataset insertion is excluded.
- Headless Chrome smoke on localhost: issue CPI 0.75/forecast 133.3h, project settings GET/POST, custom list marker and CPI column, edit baseline, jQuery selection changes, desktop/360px layout. No JavaScript console errors were reported; Redmine emitted pre-existing jQuery deprecation warnings.
- EN/BG key and interpolation parity tested. git diff --check passed.
- The shared runtime contains other plugins and emits duplicate-constant warnings from junction/physical path aliases, plus a Rails future-timezone deprecation. These did not fail the suite. This is not a plugin-only compatibility matrix.
- Temporary localhost server and headless browser were stopped after checks. Browser assets and fixture artifacts are ignored, not part of source publication.

## r5 acceptance, 2026-11-27

- Local Redmine 6.1.2 validation passed 55 Ruby tests with 366 assertions and all seven JavaScript tests.
- Staging and production used identical r5 ZIPs. Verification confirmed migrations 001 and 002, the InnoDB settings table and the compiled CSS and JavaScript.
- Browser acceptance confirmed the new tooltips in both the standard and filtered issue lists on staging and production. The project settings tab and access checks were accepted in r4.
- r5 uses the r4 schema and compiled assets. The update and rollback procedures replace only the code. Local fixtures covered rollback after a failed code swap verification.
- Request-time and memory measurements on large customer projects remain outside this acceptance.
