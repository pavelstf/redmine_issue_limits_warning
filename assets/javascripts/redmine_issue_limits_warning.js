(function () {
  window.RedmineIssueLimitsWarning = window.RedmineIssueLimitsWarning || {};

  function issueIdFromRow(row) {
    if (row.id && row.id.indexOf('issue-') === 0) {
      return row.id.replace('issue-', '');
    }

    var match = row.className.match(/(?:^|\s)issue-(\d+)(?:\s|$)/);
    return match ? match[1] : null;
  }

  function applyIssueListWarnings() {
    var statuses = window.RedmineIssueLimitsWarning.issueStatuses || {};
    var rows = document.querySelectorAll('table.list.issues tr.issue');

    rows.forEach(function (row) {
      var issueId = issueIdFromRow(row);
      var status = issueId && statuses[issueId];

      row.classList.remove(
        'rilw-time-budget-ok',
        'rilw-time-budget-warning',
        'rilw-time-budget-danger',
        'rilw-time-budget-exceeded',
        'rilw-due-date-overdue'
      );
      row.style.removeProperty('--rilw-row-color');
      row.style.removeProperty('--rilw-due-date-color');

      if (!status) {
        return;
      }

      if (status.closed) {
        return;
      }

      if (status.time_budget_enabled && status.time_budget_status) {
        row.classList.add('rilw-time-budget-' + status.time_budget_status);
        row.style.setProperty('--rilw-row-color', status.time_budget_color || '#777777');
      }

      if (status.due_date_overdue) {
        row.classList.add('rilw-due-date-overdue');
        row.style.setProperty('--rilw-due-date-color', status.due_date_color || '#dc2626');
      }
    });
  }

  function parseNumber(value) {
    if (!value) {
      return 0;
    }

    return parseFloat(String(value).replace(',', '.')) || 0;
  }

  function setupTimeEntryWarning() {
    var warning = document.querySelector('.rilw-time-entry-warning');
    if (!warning) {
      return;
    }

    var hoursInput = document.querySelector('#time_entry_hours, input[name="time_entry[hours]"]');
    if (!hoursInput) {
      return;
    }

    var spentHours = parseNumber(warning.dataset.spentHours);
    var estimatedHours = parseNumber(warning.dataset.estimatedHours);
    var dangerThreshold = parseNumber(warning.dataset.dangerThreshold);

    function refresh() {
      var newHours = parseNumber(hoursInput.value);
      var ratio = estimatedHours > 0 ? ((spentHours + newHours) / estimatedHours) * 100 : 0;
      warning.classList.toggle('rilw-visible', ratio >= dangerThreshold);
    }

    hoursInput.addEventListener('input', refresh);
    hoursInput.addEventListener('change', refresh);
    refresh();
  }

  window.RedmineIssueLimitsWarning.applyIssueListWarnings = applyIssueListWarnings;

  document.addEventListener('DOMContentLoaded', function () {
    applyIssueListWarnings();
    setupTimeEntryWarning();
  });
}());
