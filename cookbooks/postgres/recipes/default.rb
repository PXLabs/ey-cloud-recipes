require 'pp'
#
# Cookbook Name:: postgres
# Recipe:: default
#

if ['solo', 'db_master'].include?(node[:instance_role])
  postgres_root    = '/var/lib/postgresql'
  postgres_version = '8.3'

  ey_cloud_report "postgres" do
    message "upgrading postgres to 8.3.8"
  end

  package "dev-db/postgresql-server" do
    version "8.3.8"
    action :upgrade
  end
  
  directory '/db/postgresql' do
    owner 'postgres'
    group 'postgres'
    mode  '0755'
    action :create
    recursive true
  end

  directory '/var/lib/postgresql' do
    action :delete
    recursive true
  end

  link "setup-postgresq-db-my-symlink" do
    to '/db/postgresql'
    target_file postgres_root
  end

  execute "init-postgres" do
    command "initdb -D #{postgres_root}/#{postgres_version}/data --encoding=UTF8 --locale=en_US.UTF-8"
    action :run
    user 'postgres'
    only_if "[ ! -d #{postgres_root}/#{postgres_version}/data ]"
  end

  remote_file "/var/lib/postgresql/8.3/data/postgresql.conf" do
    source "postgresql.conf"
    owner "postgres"
    group "root"
    mode 0600
  end

  template "/var/lib/postgresql/8.3/data/pg_hba.conf" do
    owner 'postgres'
    group 'root'
    mode 0600
    source "pg_hba.conf.erb"
    variables({
      :dbuser => node[:users].first[:username],
      :dbpass => node[:users].first[:password]
    })
  end

  execute "enable-postgres" do
    command "rc-update add postgresql-#{postgres_version} default"
    action :run
  end

  execute "restart-postgres" do
    command "/etc/init.d/postgresql-#{postgres_version} restart"
    action :run
    not_if "/etc/init.d/postgresql-8.3 status | grep -q start"
  end

  gem_package "pg" do
    action :install
  end

  template "/etc/.postgresql.backups.yml" do
    owner 'root'
    group 'root'
    mode 0600
    source "postgresql.backups.yml.erb"
    variables({
      :dbuser => node[:users].first[:username],
      :dbpass => node[:users].first[:password],
      :keep   => node[:backup_window] || 14,
      :id     => node[:aws_secret_id],
      :key    => node[:aws_secret_key],
      :env    => node[:environment][:name]
    })
  end


  #set backup interval
  cron_hour = if node[:backup_interval].to_s == '24'
                "1"    # 0100 Pacific, per support's request
                # NB: Instances run in the Pacific (Los Angeles) timezone
              elsif node[:backup_interval]
                "*/#{node[:backup_interval]}"
              else
                "1"
              end

  cron "eybackup" do
    action :delete
  end

  cron "eybackup postgresql" do
    minute   '10'
    hour     cron_hour
    day      '*'
    month    '*'
    weekday  '*'
    command  "eybackup -e postgresql"
    not_if { node[:backup_window].to_s == '0' }
  end
  
  ey_cloud_report "postgres" do
     message "setting up app database on postgres"
  end
  
  # Setup postgis before creating the application database
  include_recipe "postgis"
end

node[:applications].each do |app_name,data|
  user = node[:users].first
  db_name = "#{app_name}_#{node[:environment][:framework_env]}"

  if ['solo', 'db_master'].include?(node[:instance_role])
    execute "create-db-user-#{user[:username]}" do
      command "psql -c '\\du' | grep -q '#{user[:username]}' || psql -c \"create user #{user[:username]} with encrypted password \'#{user[:password]}\'\""
      action :run
      user 'postgres'
    end

    execute "create-db-#{db_name}" do
      command "psql -c '\\l' | grep -q '#{db_name}' || createdb #{db_name} -T template_postgis -O #{user[:username]}"
      action :run
      user 'postgres'
    end

    execute "alter-spatial-table-perms" do
      sql = "alter table spatial_ref_sys OWNER to #{user[:username]};
             alter table geometry_columns OWNER to #{user[:username]};
             alter table geography_columns OWNER to #{user[:username]};"
      command "psql -d #{db_name} -c '#{sql}'"       
      action :run
      user 'postgres'
    end
    
    execute "grant-perms-on-#{db_name}-to-#{user[:username]}" do
      command "/usr/bin/psql -c 'grant all on database #{db_name} to #{user[:username]}'"
      action :run
      user 'postgres'
    end

    execute "alter-public-schema-owner-on-#{db_name}-to-#{user[:username]}" do
      command "/usr/bin/psql #{db_name} -c 'ALTER SCHEMA public OWNER TO #{user[:username]}'"
      action :run
      user 'postgres'
    end
  end

  directory "/data/#{app_name}/shared/config/" do
    owner user[:username]
    group user[:username]
    mode  '0755'
    action :create
    recursive true
  end
    
  template "/data/#{app_name}/shared/config/database.yml" do
    source "database.yml.erb"
    owner user[:username]
    group user[:username]
    mode 0744
    variables({
      :username => user[:username],
      :app_name => app_name,
      :db_pass => user[:password]
    })
  end
  
  script "copy-database-yml" do
    interpreter "bash"
    cwd "/data/#{app_name}/current/config/"
    code <<-EOH
      cp -f /data/#{app_name}/shared/config/database.yml /data/#{app_name}/shared/config/keep.database.yml
      chown #{user[:username]}:#{user[:username]} /data/#{app_name}/shared/config/keep.database.yml
      chmod 744 /data/#{app_name}/shared/config/keep.database.yml
      ln -sf /data/#{app_name}/shared/config/keep.database.yml database.yml
      chown #{user[:username]}:#{user[:username]} database.yml
      chmod 744 database.yml
    EOH
  end

end
