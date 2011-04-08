# 
# Installs the latest imagemagick first
# Cookbook Name:: rmagick
# Recipe:: default
#
begin
  imm_version = (`convert -version`).match(/(6\.[6-9]\.[0-9])/)
rescue
  imm_version = nil
end

begin
  rm_version = (`gem list --local | grep rmagick`).match(/2\.[1-9][3-9]\.[0-9]/)
rescue
  rm_version = nil
end

if ['solo', 'app_master','app'].include?(node[:instance_role])

  ey_cloud_report "imagemagick" do
    message "installing the latest imagemagick"
  end

  if imm_version.nil?
    package "imagemagick" do
      action :remove
    end
    
    script "install imagemagick" do
      interpreter "bash"
      cwd "/tmp"
      code <<-EOH
        wget ftp://ftp.imagemagick.org/pub/ImageMagick/ImageMagick.tar.gz
        tar xvfz ImageMagick.tar.gz
        cd ImageMagick
        export LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib"
        export LD_LIBRARY_PATH="/usr/local/lib"
        ./configure
        make
        make install
        ldconfig /usr/local/lib
      EOH
    end
  else
    Chef::Log.info "has compatible imagemagick: #{imm_version[0]}"
  end  
  
  ey_cloud_report "rmagick" do
    message "installing the latest rmagick"
  end
  
  if rm_version.nil?
    gem_package "rmagick" do
      version "2.13.1"
      action :install
    end    
  else
    Chef::Log.info "has compatible rmagick:  #{rm_version[0]}"  
  end
end