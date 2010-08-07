#
# Cookbook Name:: libxml2
# Recipe:: default
#
if ['solo','db_master'].include?(node[:instance_role])
  
  ey_cloud_report "libxml2" do
    message "upgrading libxml2 - used by postgis"
  end

  package "dev-libs/libxml2" do
    action :upgrade
  end
  
end

