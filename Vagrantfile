# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant plugin install vagrant-disksize

Vagrant.configure("2") do |config|

    config.disksize.size = "10GB"
    config.vm.box = "debian/stretch64"
    config.vm.box_check_update = false
    config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "/tmp/authorized_keys"

    config.vm.provider "virtualbox" do |v|
      v.memory = 4096
      v.cpus = 2
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end

    config.vm.define "node1", primary: true do |node1|
      node1.vm.network "private_network", ip: "172.17.0.2"
      # exposed ports
      node1.vm.network "forwarded_port", guest: 9091, host: 9091
      node1.vm.network "forwarded_port", guest: 9092, host: 9092
      node1.vm.network "forwarded_port", guest: 2181, host: 2181
      node1.vm.network "forwarded_port", guest: 3000, host: 3000
      node1.vm.network "forwarded_port", guest: 7480, host: 7480
      node1.vm.network "forwarded_port", guest: 8081, host: 8081
    end

    config.vm.provision "shell" do |s|
      s.privileged = true
      s.inline = <<-SHELL
        mkdir -p /root/.ssh
        mv /tmp/authorized_keys /root/.ssh/
        chown -R root:root /root/.ssh
        chmod -R 700 /root/.ssh
      SHELL
    end
end
