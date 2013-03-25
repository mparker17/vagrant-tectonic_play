project = "tectonicplay"

d7site = {
    'svrname'    => "#{project}.dev",
    'svraliases' => [ "www.#{project}.dev" ],
    'svrport'    => node['apache']['listen_ports'].to_a[0],
    'svrdocroot' => "/mnt/www/drupal7",
    'dbusername' => "#{project}",
    'dbpassword' => "#{project}",
    'dbdatabase' => "#{project}",
    'drupalroot' => "/mnt/www/drupal7/sites/default",
    'makedir'    => "/tmp/drupal-tectonic_play/",
    'makefile'   => "/tmp/drupal-tectonic_play/drupal-org.make",
    'repository' => "git@github.com:drupalfellows/tectonic_play.git",
    'branch'     => "develop"
}

root_database_connection = {
    :host => "localhost",
    :username => 'root',
    :password => node['mysql']['server_root_password']
}

#
# Connect to Github for the first time and memorize the signature.
#
bash "Test connecting to Github" do
    code "ssh -T git@github.com -o StrictHostKeyChecking=no ; true"
end

#
# Prepare utilities.
#
package "libapache2-mod-php5" do
    action :install
end
package "php5-gd" do
    action :install
end
package "php5-mysql" do
    action :install
end
gem_package "compass" do
    action :install
end
gem_package "mysql" do
    action :install
end
apache_module "rewrite" do
    enable
end
apache_module "php5" do
    enable
end
php_pear "Console_Table" do
    action :install
end
php_pear_channel "pear.drush.org" do
    action :discover
end
php_pear "drush" do
    channel "pear.drush.org"
    action :install
end

#
# Prepare bootstrap install profile.
#
# Apparently setting a user and group causes checkout to fail, so checkout as
# root and fix the directory permissions afterwards.
#
# This may be related to https://github.com/mitchellh/vagrant/issues/1303 and
# https://github.com/mitchellh/vagrant/pull/1307 .
#
git d7site['makedir'] do
    repository d7site['repository']
    reference d7site['branch']
    action :sync
end
bash "Fix bootstrap install profile directory permissions" do
    code "chown -R vagrant:vagrant #{d7site['makedir']}"
end

#
# Set up Drupal 7 site.
#
mysql_database d7site['dbdatabase'] do
    connection root_database_connection
    action :create
end
mysql_database_user d7site['dbusername'] do
    connection root_database_connection
    password d7site['dbpassword']
    database_name d7site['dbdatabase']
    privileges [:all]
    action :create
end
mysql_database_user site['dbusername'] do
  connection root_database_connection
  password site['dbpassword']
  action :grant
end
bash "Running drush-make for Drupal 7 site" do
    user  "vagrant"
    group "vagrant"
    code <<-EOH
        drush -y make #{d7site['makefile']} #{d7site['svrdocroot']} --working-copy --prepare-install --no-gitinfofile
    EOH
    # @TODO: Drush Make will fail if the destination exists, but in an ideal 
    # world, it would rebuild anyway because changes may have been made to the
    # build script.
    not_if "test -d #{d7site['svrdocroot']}"
end
mysql_database "Import database" do
    connection root_database_connection
    sql { ::File.open(d7site['dbfile']).read }
    action :query
end
web_app d7site['svrname'] do
    server_name d7site['svrname']
    server_aliases d7site['svraliases']
    allow_override "All"
    docroot d7site['svrdocroot']
end
template "#{d7site['drupalroot']}/settings.php" do
  source "settings_d7.php.erb"
  variables(
    :username => d7site['dbusername'],
    :password => d7site['dbpassword'],
    :database => d7site['dbdatabase']
  )
end
