(function (root) {
  'use strict';
  var api = root.RedmineIssueLimitsWarning = root.RedmineIssueLimitsWarning || {};

  // Match Redmine String#to_hours formats, rejecting partial numeric strings.
  function parseHours(value) {
    var s = String(value == null ? '' : value).trim(), match;
    if (!s) return null;
    if ((match = s.match(/^(\d+):(\d+)$/))) return Number(match[1]) + Number(match[2]) / 60;
    if ((match = s.match(/^(\d+(?:[.,]\d+)?)h?$/))) return Number(match[1].replace(',', '.'));
    if ((match = s.match(/^(?:(\d+)\s*(?:h|hours?))?\s*(?:(\d+)\s*(?:m|min)?)?$/i)) && (match[1] || match[2])) {
      return Number(match[1] || 0) + Number(match[2] || 0) / 60;
    }
    if (/^[+-]?0x[\da-f]+$/i.test(s)) {
      var hex = Number(s.replace(/^[+-]/, '')) * (s[0] === '-' ? -1 : 1);
      return Number.isFinite(hex) ? hex : null;
    }
    if (/^[+\-]?(?:\d+(?:\.\d+)?|\.\d+)(?:e[+\-]?\d+)?$/i.test(s.replace(',', '.'))) {
      var number = Number(s.replace(',', '.'));
      return Number.isFinite(number) ? number : null;
    }
    return null;
  }

  function evaluate(context, hours) {
    if (!context || !context.enabled || hours == null || hours < 0) return {status: 'unknown', reasons: []};
    var spent = context.spent_hours + hours, estimate = context.estimated_hours;
    var cpi = estimate > 0 && spent > 0 && Number.isFinite(context.done_ratio) && context.done_ratio >= 0 && context.done_ratio <= 100 ?
      Math.round(estimate * context.done_ratio / 100 / spent * 1e12) / 1e12 : null;
    var status = 'unknown', reasons = [];
    if (context.cpi_enabled && cpi != null) {
      status = cpi < context.cpi_danger ? 'danger' : cpi < context.cpi_warning ? 'warning' : 'ok';
      if (status === 'warning' || status === 'danger') reasons.push('cpi');
    }
    if (context.absolute_limit_enabled && estimate > 0 && spent / estimate * 100 >= context.absolute_limit_threshold) {
      status = 'danger'; reasons.push('limit');
    }
    return {status: status, reasons: reasons, cpi: cpi};
  }

  var markerTitles = new WeakMap();

  function setMarkerTitle(cell, title) {
    var old = markerTitles.get(cell);
    if (old) {
      if (cell.getAttribute('title') === old.applied) {
        if (old.original === null) cell.removeAttribute('title');
        else cell.setAttribute('title', old.original);
      }
      markerTitles.delete(cell);
    }
    if (!title) return;
    var original = cell.getAttribute('title');
    var applied = original ? title + ' · ' + original : title;
    cell.setAttribute('title', applied);
    markerTitles.set(cell, {original: original, applied: applied});
  }

  function applyIssueListWarnings() {
    var statuses = api.issueStatuses || {};
    document.querySelectorAll('table.list.issues tr.issue').forEach(function (row) {
      var match = (row.id || '').match(/^issue-(\d+)$/) || row.className.match(/(?:^|\s)issue-(\d+)(?:\s|$)/);
      var status = match && statuses[match[1]];
      ['ok', 'warning', 'danger', 'exceeded', 'unknown'].forEach(function (name) { row.classList.remove('rilw-time-budget-' + name); });
      row.classList.remove('rilw-due-date-overdue');
      row.style.removeProperty('--rilw-row-color'); row.style.removeProperty('--rilw-due-date-color');
      if (status && status.closed) status = null;
      var budgetTitle = status && status.time_budget_enabled && status.time_budget_title;
      row.querySelectorAll('td.spent_hours, td.estimated_hours').forEach(function (cell) {
        setMarkerTitle(cell, budgetTitle);
      });
      var dueCell = row.querySelector('td.due_date');
      if (dueCell) setMarkerTitle(dueCell, status && status.due_date_overdue && status.due_date_title);
      if (!status) return;
      if (status.time_budget_enabled) {
        row.classList.add('rilw-time-budget-' + status.time_budget_status);
        row.style.setProperty('--rilw-row-color', status.time_budget_color);
      }
      if (status.due_date_overdue) {
        row.classList.add('rilw-due-date-overdue'); row.style.setProperty('--rilw-due-date-color', status.due_date_color);
      }
    });
  }

  function setupTimeEntryWarning() {
    var warning = document.querySelector('.rilw-time-entry-warning');
    var hours = document.querySelector('#time_entry_hours, input[name="time_entry[hours]"]');
    if (!warning || !hours || warning.dataset.initialized) return;
    warning.dataset.initialized = '1';
    var context = null, generation = 0;
    function render() {
      var result = evaluate(context, parseHours(hours.value));
      warning.textContent = result.reasons.map(function (reason) { return reason === 'cpi' ? warning.dataset.cpiMessage : warning.dataset.limitMessage; }).join(' · ');
      warning.classList.toggle('rilw-visible', result.reasons.length > 0);
      if (context) warning.style.setProperty('--rilw-color', result.status === 'danger' ? context.danger_color : context.warning_color);
    }
    function loadContext() {
      var request = ++generation;
      context = null; render();
      var selector = document.querySelector('#time_entry_issue_id');
      var issueId = selector ? selector.value : warning.dataset.issueId;
      if (!/^\d+$/.test(issueId || '')) return;
      var url = new URL(warning.dataset.contextUrl, window.location.origin);
      url.searchParams.set('issue_id', issueId);
      if (warning.dataset.entryId) url.searchParams.set('time_entry_id', warning.dataset.entryId);
      fetch(url.toString(), {credentials: 'same-origin', headers: {'Accept': 'application/json'}})
        .then(function (response) { if (!response.ok) throw new Error('Unavailable context'); return response.json(); })
        .then(function (data) { if (request === generation) { context = data; render(); } })
        .catch(function () { if (request === generation) { context = null; render(); } });
    }
    hours.addEventListener('input', render); hours.addEventListener('change', render);
    if (root.jQuery) {
      // Redmine autocomplete uses .val(...).change(), which is a jQuery event.
      root.jQuery(document).on('change.rilw', '#time_entry_issue_id,#time_entry_project_id', loadContext);
    } else {
      document.addEventListener('change', function (event) {
        if (event.target.id === 'time_entry_issue_id' || event.target.id === 'time_entry_project_id') loadContext();
      });
    }
    document.addEventListener('input', function (event) { if (event.target.id === 'time_entry_issue_id') loadContext(); });
    loadContext();
  }
  api.parseHours = parseHours; api.evaluate = evaluate; api.applyIssueListWarnings = applyIssueListWarnings;
  api.setupTimeEntryWarning = setupTimeEntryWarning;
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (typeof document !== 'undefined') document.addEventListener('DOMContentLoaded', function () { applyIssueListWarnings(); setupTimeEntryWarning(); });
}(typeof window !== 'undefined' ? window : globalThis));
