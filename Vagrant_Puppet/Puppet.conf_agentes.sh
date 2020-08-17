#!/bin/bash 

#Modificar archivo puppet.conf para que sepan quien es el puppetmaster


sudo echo "[main]"                                    >> /etc/puppetlabs/puppet/puppet.conf
sudo echo "certname = $(hostname)"                    >> /etc/puppetlabs/puppet/puppet.conf
sudo echo "server   = puppet.example.com"             >> /etc/puppetlabs/puppet/puppet.conf


