# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<-SCRIPT
#Actualizacion del box y instalacion de puppetmaster
sudo apt-get -y update
sudo apt-get -y upgrade    
sudo timedatectl set-timezone "America/Bogota"
sudo hostnamectl set-hostname puppet               
#Instalacion de puppetserver y puppetagent
sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt-get -y update
sudo apt-get -y upgrade 
sudo apt-get -y install puppet-agent
sudo apt-get -y install puppetserver
sudo ufw allow 8140   
# Activacion de servicios
sudo systemctl  start      puppetserver.service
sudo systemctl  enable       puppetserver.service
SCRIPT

$script2 = <<-SCRIPT
#Actualizacion del box y instalacion de puppetagent
sudo apt-get -y update
sudo apt-get -y upgrade    
sudo timedatectl set-timezone "America/Bogota"
#Instalacion de puppetserver y puppetagent
sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install puppet-agent
# Activacion de servicios
sudo systemctl  start   puppet.service
sudo systemctl  enable  puppet.service
SCRIPT


#Maquina puppet master

Vagrant.configure('2') do |config|
    config.vm.define "puppet" do |puppet|

# Box a utilizar, previamente descargado
        puppet.vm.box = 'ubuntu/xenial64'

#Hostname
        puppet.vm.hostname = "puppet"

#IP privada
        puppet.vm.network 'private_network', ip: '192.168.20.23'


#Aprovisionamiento de maquina 

        puppet.vm.provision "shell", inline:  $script, privileged: true
        puppet.vm.provision "shell", path:    "añadir_hostname.sh",  privileged: true


#Personalizar maquina virtual    
        puppet.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", 3072]   

        end 
    end



#Nodo de trabajo 1 

         config.vm.define "puppetagent1" do |puppetagent1|

# Box a utilizar, previamente descargado

        puppetagent1.vm.box = 'ubuntu/xenial64'

#Hostname

        puppetagent1.vm.hostname = "puppetagent1"

#IP privada

        puppetagent1.vm.network 'private_network', ip: '192.168.20.21'

#Aprovisionamiento de maquina 

        puppetagent1.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent1"
        puppetagent1.vm.provision "shell", inline:  $script2, privileged: true 
        puppetagent1.vm.provision "shell", path:   "añadir_hostname.sh", privileged: true
        puppetagent1.vm.provision "shell", path:   "Puppet.conf_agentes.sh", privileged: true
         

    end 


#Nodo de trabajo2

        config.vm.define "puppetagent2" do |puppetagent2|

# Box a utilizar, previamente descargado

        puppetagent2.vm.box = 'ubuntu/xenial64'

#Hostname

        puppetagent2.vm.hostname = "puppetagent2"

#IP privada

        puppetagent2.vm.network 'private_network', ip: '192.168.20.22'

#Aprovisionamiento de maquina 

        puppetagent2.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent2"
        puppetagent2.vm.provision "shell", inline:  $script2, privileged: true
        puppetagent2.vm.provision "shell", path:   "añadir_hostname.sh",     privileged: true
        puppetagent2.vm.provision "shell", path:   "Puppet.conf_agentes.sh", privileged: true
            

    end 


end
