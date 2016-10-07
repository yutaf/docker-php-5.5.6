# -*- mode: ruby -*-
# vi: set ft=ruby :

Dotenv.load

Vagrant.configure('2') do |config|
  config.vm.define "my-do-php-5.5.6" # vagrant machine name
  config.vm.provider :digital_ocean do |provider, override|
    override.vm.hostname = "vagrant-my-docker-php-5.5.6" # droplet name
    override.ssh.private_key_path = ENV['DO_SSH_KEY']
    override.vm.box = 'digital_ocean'
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"

    provider.token = ENV['PERSONAL_TOKEN']
    provider.image = ENV['DO_IMAGE']
    provider.region = 'sgp1'
    provider.size = ENV['DO_SIZE']
    provider.ssh_key_name = 'vagrant'
  end
end
