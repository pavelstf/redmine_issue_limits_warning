const assert = require('node:assert/strict');
const test = require('node:test');
const api = require('../../assets/javascripts/redmine_issue_limits_warning.js');
const vm = require('node:vm');
const fs = require('node:fs');

test('issue list marker hints are cleared on refresh and native titles are restored', () => {
  const cell = (title = null) => ({
    getAttribute: () => title,
    setAttribute: (_key, value) => { title = value; },
    removeAttribute: () => { title = null; }
  });
  const estimate = cell('Estimated hours');
  const spent = cell();
  const due = cell();
  const classes = new Set();
  const row = {
    id: 'issue-42',
    classList: {add: name => classes.add(name), remove: name => classes.delete(name)},
    style: {setProperty() {}, removeProperty() {}},
    querySelectorAll: () => [estimate, spent],
    querySelector: () => due
  };
  const window = {};
  const document = {addEventListener() {}, querySelectorAll: () => [row]};
  vm.runInNewContext(fs.readFileSync(require.resolve('../../assets/javascripts/redmine_issue_limits_warning.js'), 'utf8'),
    {window, document});
  const markers = window.RedmineIssueLimitsWarning;
  markers.issueStatuses = {42: {time_budget_enabled: true, time_budget_status: 'danger',
    time_budget_title: 'CPI: 0.75 · Critical', due_date_overdue: true, due_date_title: 'Overdue issue'}};
  markers.applyIssueListWarnings();
  markers.applyIssueListWarnings();
  assert.equal(estimate.getAttribute('title'), 'CPI: 0.75 · Critical · Estimated hours');
  assert.equal(spent.getAttribute('title'), 'CPI: 0.75 · Critical');
  assert.equal(due.getAttribute('title'), 'Overdue issue');
  assert(classes.has('rilw-time-budget-danger'));
  markers.issueStatuses[42] = {time_budget_enabled: false, time_budget_status: 'ok',
    due_date_overdue: true, due_date_title: 'Overdue issue'};
  markers.applyIssueListWarnings();
  assert(!classes.has('rilw-time-budget-ok'));
  assert.equal(estimate.getAttribute('title'), 'Estimated hours');
  assert.equal(spent.getAttribute('title'), null);
  assert.equal(due.getAttribute('title'), 'Overdue issue');
  markers.issueStatuses[42].closed = true;
  markers.applyIssueListWarnings();
  assert.equal(due.getAttribute('title'), null);
  assert(!classes.has('rilw-due-date-overdue'));
});

test('Redmine duration formats and invalid input', () => {
  for (const [input, expected] of require('../duration_cases.json')) {
    assert.equal(api.parseHours(input), expected, input);
  }
  for (const [value, hours] of [['1.5',1.5],['1,5',1.5],['1:30',1.5],['1h30',1.5],['1h',1],['90m',1.5],['2 hours',2],['30 min',0.5],[' 2H 15MIN ',2.25]]) {
    assert.equal(api.parseHours(value), hours, value);
  }
  for (const value of ['', 'junk', '1.5junk', 'Infinity', 'NaN']) assert.equal(api.parseHours(value), null);
});

const context = {enabled: true, spent_hours: 0, estimated_hours: 100, done_ratio: 90,
  cpi_enabled: true, cpi_warning: 0.9, cpi_danger: 0.8, absolute_limit_enabled: false, absolute_limit_threshold: 120};
test('CPI exact boundaries and unavailable data', () => {
  assert.equal(api.evaluate(context,100).status,'ok');
  assert.equal(api.evaluate({...context,done_ratio:80},100).status,'warning');
  assert.equal(api.evaluate({...context,done_ratio:79},100).status,'danger');
  assert.equal(api.evaluate(context,0).status,'unknown');
  assert.equal(api.evaluate({...context,estimated_hours:0},10).status,'unknown');
  assert.equal(api.evaluate({...context,done_ratio:0},10).status,'danger');
  assert.equal(api.evaluate({...context,done_ratio:101},10).status,'unknown');
  assert.deepEqual(api.evaluate(context,null).reasons,[]);
});
test('edit uses baseline excluding original entry and supports Redmine duration', () => {
  const edit = {...context,estimated_hours:10,done_ratio:90,spent_hours:7};
  assert.equal(api.evaluate(edit,api.parseHours('1:30')).status,'ok');
  assert.equal(api.evaluate({...edit,spent_hours:9},1.5).status,'warning');
});
test('absolute limit above 100 percent is independent', () => {
  const settings = {...context,cpi_enabled:false,absolute_limit_enabled:true};
  assert.deepEqual(api.evaluate(settings,110).reasons,[]);
  assert.deepEqual(api.evaluate(settings,120).reasons,['limit']);
});

for (const jquery of [false,true]) test(`dynamic selection (${jquery ? 'jQuery autocomplete' : 'native'}): stale responses and unavailable context`, async () => {
  const listeners = {}, pending = [], classes = new Set();
  const warning = {dataset: {contextUrl:'/context',entryId:'12',issueId:'1',cpiMessage:'CPI',limitMessage:'Limit'},
    classList: {toggle: (key,on) => on ? classes.add(key) : classes.delete(key)}, style: {setProperty() {}},textContent:''};
  const hours = {value:'20',addEventListener: (name,fn) => {listeners['hours:'+name]=fn;}};
  const issue = {id:'time_entry_issue_id',value:'1'};
  const doc = {querySelector: q => q === '.rilw-time-entry-warning' ? warning : q === '#time_entry_issue_id' ? issue : hours,
    addEventListener: (name,fn) => {listeners[name]=fn;}};
  const window = {location:{origin:'https://qa.example.test'}};
  if (jquery) window.jQuery = () => ({on: (_event,_selector,callback) => {listeners.change=callback;}});
  const sandbox = {window,document:doc,URL,fetch:(url) => new Promise(resolve => pending.push({url,resolve}))};
  vm.runInNewContext(fs.readFileSync(require.resolve('../../assets/javascripts/redmine_issue_limits_warning.js'),'utf8'),sandbox);
  window.RedmineIssueLimitsWarning.setupTimeEntryWarning();
  assert.equal(pending.length,1);
  assert.match(pending[0].url,/time_entry_id=12/);
  issue.value='2'; listeners.change({target:issue});
  assert.equal(pending.length,2);
  pending[1].resolve({ok:true,json:async()=>({...context,done_ratio:10})});
  await new Promise(resolve=>setImmediate(resolve));
  assert(classes.has('rilw-visible'));
  pending[0].resolve({ok:true,json:async()=>context});
  await new Promise(resolve=>setImmediate(resolve));
  assert(classes.has('rilw-visible'),'older response must not replace the current issue');
  issue.value=''; listeners.input({target:issue});
  assert(!classes.has('rilw-visible'));
  assert.equal(listeners.submit,undefined);
  issue.value='3';listeners.change({target:issue});
  pending[2].resolve({ok:false});
  await new Promise(resolve=>setImmediate(resolve));
  assert(!classes.has('rilw-visible'));
});
