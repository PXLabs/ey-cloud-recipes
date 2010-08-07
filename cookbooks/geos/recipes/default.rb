#
# Cookbook Name:: geos
# Recipe:: default
#
if ['solo','db_master'].include?(node[:instance_role])
  
  ey_cloud_report "GEOS" do
    message "installing GEOS library - used by postgis"
  end
  
  script "install_geos" do 
    interpreter "bash"
    cwd "/tmp"
    code <<-EOH
      wget http://download.osgeo.org/geos/geos-3.2.2.tar.bz2
      tar -xvf geos-3.2.2.tar.bz2
      cd geos-3.2.2
      ./configure
      make
      make install
      ldconfig
    EOH
  end
end