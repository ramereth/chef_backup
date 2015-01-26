require 'simplecov'
SimpleCov.start

require 'chef_backup'
require 'bundler/setup'
require 'json'
require 'tempfile'
require 'chef/mixin/deep_merge'

def private_chef(*args)
  Chef::Mixin::DeepMerge.deep_merge!(*args, ChefBackup::Config['private_chef'])
end

def reset_config
  ChefBackup::Config.config = running_config
end

def set_common_variables
  let(:backup_tarball) { '/tmp/chef-backup-2014-12-10-20-31-40.tgz' }
  let(:backup_time) { '2014-08-21T23:10:57-07:00' }
  let(:tmp_dir) { '/tmp/chef-backup' }
  let(:strategy) { 'test' }
  let(:export_dir) { '/mnt/chef-backups' }
  let(:all_services) do
    %w(nginx oc_bifrost oc_id opscode-erchef opscode-expander
       opscode-expander-reindexer opscode-solr4 postgresql rabbitmq redis_lb
    )
  end
  let(:enabled_services) { all_services }
  let(:data_map) do
    double(
      'DataMap',
      services: {
        'postgresql' => {
          'data_dir' => '/var/opt/opscode/postgresql_9.2/data'
        },
        'couchdb' => {
          'data_dir' => '/var/opt/opscode/couchdb/data'
        },
        'rabbitmq' => {
          'data_dir' => '/var/opt/opscode/rabbitdb/data'
        }
      },
      configs: {
        'opscode' => {
          'data_dir' => '/etc/opscode'
        },
        'opscode-manage' => {
          'data_dir' => '/etc/opscode-manage'
        }
      }
    )
  end
end

def running_config
  @config ||= begin
    f = File.expand_path('../fixtures/chef-server-running.json', __FILE__)
    JSON.parse(File.read(f))
  end
  @config.dup
end

# TODO: These NOOP methods are nasty hacks.  Need to refactor the hell out of
# this.
def noop_external_methods(methods = external_methods_as_symbols)
  methods.each { |symbol| allow(subject).to receive(symbol).and_return(true) }
end

def noop_external_methods_except(methods)
  methods = [methods] unless methods.is_a?(Array)
  noop_external_methods((external_methods_as_symbols - methods))
end

def external_methods_as_symbols
  %i(
    shell_out! shell_out start_service stop_service service_enabled?
    backup_opscode_config create_tarball write_manifest cleanup export_tarball
  )
end

RSpec.configure do |rspec|
  rspec.run_all_when_everything_filtered = true
  rspec.filter_run :focus
  rspec.order = 'random'
  rspec.expect_with(:rspec) { |c| c.syntax = :expect }
  rspec.before { allow($stdout).to receive(:write) }
  rspec.before(:each) { reset_config }
end
