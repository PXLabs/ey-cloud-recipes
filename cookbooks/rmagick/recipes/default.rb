# 
# Installs the latest imagemagick first
# Cookbook Name:: rmagick
# Recipe:: default
#
begin
  imm_version = (`convert -version`).match(/(6\.[8-9]\.[0-9])/)
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
    message "installing not the latest imagemagick"
  end

  package "imagemagick" do
    action :remove
  end

  if imm_version.nil?
    script "install imagemagick" do
      interpreter "bash"
      cwd "/tmp"
      #wget ftp://ftp.imagemagick.org/pub/ImageMagick/ImageMagick.tar.gz
      code <<-EOH
        #wget ftp://ftp.imagemagick.org/pub/ImageMagick/releases/ImageMagick-6.7.6-10.tar.gz
        wget ftp://ftp.imagemagick.org/pub/ImageMagick/releases/ImageMagick-6.9.0-0.tar.gz
        mv ImageMagick*tar.gz ImageMagick.tar.gz
        tar xvfz ImageMagick.tar.gz
        rm ImageMagick.tar.gz
        mv ImageMagick* ImageMagick
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
    execute "install RMagick" do
      command "export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib64/pkgconfig/;C_INCLUDE_PATH=/usr/local/include/ImageMagick gem install rmagick"
      #command "gem install rmagick"
    end
    #gem_package "rmagick" do
    #  version "2.13.1"
    #  action :install
    #end
  else
    Chef::Log.info "has compatible rmagick:  #{rm_version[0]}"
  end
end
