# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# @file
# Specify settings for a tectonic_play server.
#
# Vagrant v1.1.4
#
Vagrant.configure("2") do |config|
  # Machine settings.
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.hostname = "tectonicplay.dev"
  config.vm.network :forwarded_port, guest: 80, host: 8080
  # To use NFS folders, we have to use a private (host-only) network with a
  # static IP.
  config.vm.network :private_network, ip: "192.168.33.10"
  config.vm.synced_folder "./data/html", "/mnt/www", :nfs => true

  # SSH settings.
  config.ssh.forward_agent = true

  #
  # Provision the machine.
  #

  # Refresh package list before attempting to install software.
  config.vm.provision :shell, :inline => "apt-get update"

  # Ensure we keep the SSH_AUTH_SOCK variable when sudoing.
  config.vm.provision :shell do |shell|
    shell.inline = "touch $1 && chmod 0440 $1 && echo $2 > $1"
    shell.args = %q{/etc/sudoers.d/root_ssh_agent "Defaults env_keep += \"SSH_AUTH_SOCK\""}
  end

  # Guest machine software specification.
  # Note that, when running `vagrant up`, the cookbooks specified in the
  # `add_recipe()` calls below **must already be present** in the directory
  # specified by `chef.cookbooks_path`. (i.e.: you git-clone--recurive'd).
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"

    # Config.
    chef.json = {
      "mysql" => {
        "server_root_password" => "root",
        "server_repl_password" => "root",
        "server_debian_password" => "root"
      }
    }

    # Webserver basics.
    chef.add_recipe("apache2")
    chef.add_recipe("php")
    chef.add_recipe("mysql::server")
    chef.add_recipe("database")

    # Development basics.
    chef.add_recipe("build-essential")
    chef.add_recipe("git")
    chef.add_recipe("vim")

    # Finally, install the project.
    chef.add_recipe("tectonic_play")
  end
end
