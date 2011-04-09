#
# Cookbook Name:: pg_adapter_fix
# Recipe:: default
#
if ['solo', 'app_master','app'].include?(node[:instance_role])
  # Delete the messed up file first
  file "/usr/lib64/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/postgresql_adapter.rb" do
    action :delete
  end

  remote_file "/usr/lib64/ruby/gems/1.8/gems/activerecord-2.3.5/lib/active_record/connection_adapters/postgresql_adapter.rb" do
    source "postgresql_adapter.rb"
    owner "root"
    group "root"
    mode 0644
  end
end