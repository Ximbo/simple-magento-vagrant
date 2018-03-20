# -*- mode: ruby -*-
# vi: set ft=ruby :

# To install store sample data
sample_data = "false"

host = "magento1.test"
ip = "192.168.10.101"
cpus = "2"
memory = "2048"
synced_type = "nfs"

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/trusty64"
  
  config.vm.provision :shell, :path => "bootstrap.sh", :args => [sample_data, host]

  # Configure Port Forwarding
  config.vm.network 'forwarded_port', guest: 80, host: 8000
  config.vm.network 'forwarded_port', guest: 3306, host: 33060
  config.vm.network 'forwarded_port', guest: 5432, host: 54320
  config.vm.network 'forwarded_port', guest: 35729, host: 35729
  config.vm.network :private_network, ip: ip

  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |vb|
    vb.name = host
    vb.customize [
      "modifyvm", :id,
      "--name", host,
      "--memory", memory,
      "--natdnshostresolver1", "on",
      "--cpus", cpus,
    ]
  end

  # config.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=666"]
  config.vm.synced_folder "../", "/vagrant", type: synced_type, mount_options: ['actimeo=1','nolock', 'vers=3', 'udp', 'noatime']
end
