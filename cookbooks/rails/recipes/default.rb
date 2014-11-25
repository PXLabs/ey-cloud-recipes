execute "install Rails 2.3.18" do
  command "gem install rails --version 2.3.18"
end

execute "install iconv" do
  command "gem install iconv"
end

execute "install test-unit" do
  command "gem install test-unit --version 2.3.2"
end

execute "install activerecord-postgresql-adapter" do
  command "gem install activerecord-postgresql-adapter"
end

execute "install uuidtools" do
  command "gem install uuidtools"
end

execute "install delayed_job" do
  command "gem install delayed_job --version 2.0.3"
end

execute "install aws-s3" do
  command "gem install aws-s3"
end


