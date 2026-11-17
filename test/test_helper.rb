redmine_root = ENV.fetch('REDMINE_ROOT') { File.expand_path('../../..', __dir__) }
require File.join(redmine_root, 'test/test_helper')
