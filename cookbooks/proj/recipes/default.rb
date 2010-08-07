#
# Cookbook Name:: proj
# Recipe:: default
#
if ['solo','db_master'].include?(node[:instance_role])
  
  ey_cloud_report "Proj" do
    message "installing proj library - used by postgis"
  end
  
  script "install_proj" do 
    interpreter "bash"
    cwd "/tmp"
    code <<-EOH
      wget http://download.osgeo.org/proj/proj-4.7.0.tar.gz
      tar -xvf proj-4.7.0.tar.gz
      wget http://download.osgeo.org/proj/proj-datumgrid-1.5.zip
      unzip proj-datumgrid-1.5.zip  -d  proj-4.7.0/nad
      cd proj-4.7.0
      ./configure
      make
      make install
      ldconfig
    EOH
  end
end