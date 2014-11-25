recipes('main')
#owner_name(@attribute[:users].first[:username])
#owner_pass(@attribute[:users].first[:password])

default[:owner_name] = node[:users].first[:username]
default[:owner_pass] = node[:users].first[:password]
