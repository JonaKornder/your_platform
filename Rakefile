#!/usr/bin/env rake

# Load demo application environment.
# 
require File.expand_path('../demo_app/my_platform/config/application', __FILE__)


# Do not load the application tasks for the moment, which would
# invoke test:prepare, which has been dropped.
# 
# # MyPlatform::Application.load_tasks


# Use rspec-rerun as default task.
# 
#   - rake
#   - rake rspec-rerun:spec
#
require 'rspec/core/rake_task'
require 'rspec-rerun'

ENV['RSPEC_RERUN_RETRY_COUNT'] ||= '3'
ENV['RSPEC_RERUN_PATTERN'] ||= "{./spec/**/*_spec.rb}"

task default: 'rspec-rerun:spec'


# Version bumping mechanism.
# See: https://gist.github.com/grosser/1261469
#
#   - rake version:bump:major
#   - rake version:bump:minor
#   - rake version:bump:patch
#
rule /^version:bump:.*/ do |t|
  sh "git status | grep 'nothing to commit'" # ensure we are not dirty
  index = ['major', 'minor','patch'].index(t.name.split(':').last)
  file = 'lib/your_platform/version.rb'
 
  version_file = File.read(file)
  old_version, *version_parts = version_file.match(/(\d+)\.(\d+)\.(\d+)/).to_a
  version_parts[index] = version_parts[index].to_i + 1
  version_parts[2] = 0 if index < 2
  version_parts[1] = 0 if index < 1
  new_version = version_parts * '.'
  File.open(file,'w'){|f| f.write(version_file.sub(old_version, new_version)) }
 
  sh "bundle && git add #{file} Gemfile.lock && git commit -m 'bump version to #{new_version}.'"
end