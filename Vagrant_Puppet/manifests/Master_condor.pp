node 'puppetagent1' {


#Apt-get update de la lista de repositorios

 exec { "UPDATE":
   command => '/usr/bin/apt-get update'
}


#Recurso para instalar HTCondor

package { 'htcondor':
    ensure => '8.4*',
}


#Recurso para modificar el archivo de configuracion de HTCONDOR

file { "/home/ubuntu/condor_config.local":
 ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '644',
    source => 'puppet:///modules/condor/condor_config_master.local',
}

#Sobreescritura del archivo de configuracion de condor

 exec { "CP_CONFIG": 
    command => '/bin/cp -rp /home/ubuntu/condor_config.local /etc/condor',
}


#Recurso para modificar el archivo de configuracion de HTCONDOR y asignar su IP correspondiente 

file { "/home/ubuntu/add_ip.sh":
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '644',
    source => 'puppet:///modules/condor/add_ip.sh',
}


exec {"IP_CONFIG":
   command => '/bin/sh /home/ubuntu/add_ip.sh',
}


#Recurso para iniciar el servicio de HTCondor

service {'condor':
        ensure => running,
        enable => true,
}



}

