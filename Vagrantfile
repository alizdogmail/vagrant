# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  # --- Máquina 1: Ubuntu Server ELKS ---
  config.vm.define "srvelks" do |srvelks|
  # Box de Ubuntu, 24.0.4
	srvelks.vm.box = "bento/ubuntu-24.04"
	srvelks.vm.provision "shell", path: "elks-auto.sh"
    srvelks.vm.hostname = "srvelks"
    # Red NAT (por defecto)
	srvelks.vm.network "private_network", ip: "192.168.128.11"
    srvelks.vm.network "forwarded_port", guest: 22, host: 2201, auto_correct: true, id: "ssh"
	srvelks.vm.network "forwarded_port", guest: 5601, host: 5602
	srvelks.vm.network "forwarded_port", guest: 9200, host: 9201
    srvelks.vm.provider "virtualbox" do |vb|
      vb.memory = "6144"
      vb.cpus = 2
    end
  end
  config.vm.define "srvwp" do |srvwp|
  # Box de Ubuntu, 24.0.4
	srvwp.vm.box = "bento/ubuntu-24.04"	
	srvwp.vm.provision "shell", path: "wp-filebeat.sh"
    srvwp.vm.hostname = "srvwp"
    # Red NAT (por defecto)
	srvwp.vm.network "private_network", ip: "192.168.128.12"
    srvwp.vm.network "forwarded_port", guest: 22, host: 2211, auto_correct: true, id: "ssh"
	srvwp.vm.network "forwarded_port", guest: 80, host: 8080
    srvwp.vm.provider "virtualbox" do |vb|
      vb.memory = "3072"
      vb.cpus = 2
    end
  end
  
end