require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  #t.rspec_path = 'bin/rspec'
  t.rspec_opts = ["--color", "--format nested"]
end

task :default => :spec
