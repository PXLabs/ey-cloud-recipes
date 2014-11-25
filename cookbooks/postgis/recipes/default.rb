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
      wget http://download.osgeo.org/postgis/source/postgis-2.1.3.tar.gz
      tar xfz postgis-2.1.3.tar.gz
      cd postgis-2.1.3

      ./configure
      make
      make install
      ldconfig
      make comments-install

      sudo ln -sf /usr/share/postgresql-common/pg_wrapper /usr/local/bin/shp2pgsql
      sudo ln -sf /usr/share/postgresql-common/pg_wrapper /usr/local/bin/pgsql2shp
      sudo ln -sf /usr/share/postgresql-common/pg_wrapper /usr/local/bin/raster2pgsql
    EOH
  end

  #script "init-postgis-template" do
  #  interpreter "bash"
  #  code <<-EOH
  #    createdb template_postgis
  #    psql -d template_postgis -c "CREATE LANGUAGE plpgsql"
  #    psql -d template_postgis -f /usr/share/postgresql-8.3/contrib/postgis-1.5/postgis.sql
  #    psql -d template_postgis -f /usr/share/postgresql-8.3/contrib/postgis-1.5/spatial_ref_sys.sql
  #  EOH
  #  user 'postgres' 
  #end
  #
  script "enable-postgis" do
    interpreter "bash"
    code <<-EOH
      psql -d template_postgis -c "CREATE EXTENSION postgis;"
    EOH
    user 'postgres'
  end

end
