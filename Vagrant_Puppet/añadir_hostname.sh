#!/bin/bash 

sudo cp  -r /vagrant/hosts /etc/hosts 

#Modificar archivo hosts 
numero=$(hostname -i)
nombre=$(hostname)

linea=$numero$nombre

echo "$linea">> /etc/hosts

