#
# Cookbook Name:: postgis
# Recipe:: default
#
install_postgis = false
if ['solo', 'db_master'].include?(node[:instance_role])
  begin
    pg_tmplt = (`psql -U postgres -c '\\l'`).match(/template_postgis/)
    install_postgis = true if pg_tmplt.nil?
  rescue Exception => e
    install_postgis = true
  end
end

Chef::Log.info "install_postgis:  #{install_postgis}"

if install_postgis == true

  ey_cloud_report "postgis" do
    message "installing postgis 1.5.1"
  end
  
  include_recipe "proj"
  include_recipe "geos"
  include_recipe "libxml2"

  script "install_postgis" do 
    interpreter "bash"
    cwd "/tmp"
    code <<-EOH
      wget http://www.postgis.org/download/postgis-1.5.1.tar.gz
      tar -xvf postgis-1.5.1.tar.gz
      cd postgis-1.5.1
      ./configure
      make
      make install
      ldconfig
    EOH
  end
  
  script "init-postgis-template" do
    interpreter "bash"
    code <<-EOH
      createdb template_postgis
      psql -d template_postgis -c "CREATE LANGUAGE plpgsql"
      psql -d template_postgis -f /usr/share/postgresql-8.3/contrib/postgis-1.5/postgis.sql
      psql -d template_postgis -f /usr/share/postgresql-8.3/contrib/postgis-1.5/spatial_ref_sys.sql
    EOH
    user 'postgres' 
  end
  
  link "/usr/bin/shp2pgsql" do 
    to "/usr/lib/postgresql-8.3/bin/shp2pgsql"
  end
  
end