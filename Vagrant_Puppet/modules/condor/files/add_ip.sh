#!/bin/bash

#Obtener direccion IP de la maquina
a="NETWORK_INTERFACE ="

Ip=$(hostname -i | awk '{print $1}')

#Concatenamos las dos variables anteriores

Linea=$a$Ip

#Imprimimos resultado

echo "$Linea">>/etc/condor/condor_config.local

