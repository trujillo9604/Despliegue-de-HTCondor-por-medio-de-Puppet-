# Pasos para ejecución

Ejecutar el script `iniciar.sh` 

    ./iniciar.sh


Finalizada la ejecucion del script, ejecutar todo lo relacionado con Puppet en modo root. Copiar las carpetas "modules" y "manifest" de /vagrant a /etc/puppetlabs/code/enviroment/production

    sudo cp -r /vagrant/modules/condor /etc/puppetlabs/code/environments/production/modules/
    sudo cp -r /vagrant/manifests/ /etc/puppetlabs/code/environments/production/

Configurar la certificacion de clientes puppet por parte de puppet master:


    sudo /opt/puppetlabs/bin/puppet cert sign --all
    sudo systemctl restart puppetserver.service

Ahora nos dirigimos al `puppetagent1` y verificamos su funcionamiento con el puppetmaster


    vagrant ssh puppetagent1
    sudo /opt/puppetlabs/puppet/bin/puppet agent -t

Por ultimo nos dirigimos al `puppetagent2` y realizamos el proceso anterior. 

    vagrant ssh puppetagent2
    sudo /opt/puppetlabs/puppet/bin/puppet agent -t

Nos aseguramos que el despliegue de HTCondor se encuentre correctamente configurado, dirigiendonos nuevamente al `puppetagent1`


    vagrant ssh puppetagent1
    condor_status 
    condor_q
    
Con los comandos descritos anteriormente se observa el pool de HTCondor y la información relaciona con trabajos en la cola de tareas, respectivamente.


# Explicacion del fichero Vagrant file, con relacion a la instalacion y configuracion de Puppet por medio de Vagrant

El procedimiento a realizar esta dado por el despliegue y configuracion de Puppet. Posteriormente se anexan los manifest, files y scripts que soportan el despliegue y configuración de HTCondor a través de Puppet. 

El entorno en el que se desarrolla este proyecto esta dado por 3 maquinas virtuales, generadas con Vagrant (herramienta para la creación y configuración de entornos de desarrollo virtualizados). Se tendran dos arquitecturas desplegadas con la ayuda de Vagrant, el cual sera master-agent, perteneciente al gestor de configuracion Puppet y al finalizar el despliegue y configuracion de Puppet, se tendra otra arquitectura perteneciente a HTCondor (master-worker), la cual nos la facilitara el gestor de configuracion Puppet. Estas tres maquinas virtuales tendran como nombre: 

* puppet, quien asume el rol de Puppet master, 

* puppetagent1 y puppetagent2, quienes seran las maquinas encargadas de ser dotadas por un gestor de cola de tareas, a traves de Puppet y a su ves seran             clientes puppet.

Finalizado el despliegue de Puppet, se debera certificar los clientes Puppet de forma manual. El Puppet master debe aprobar una solicitud de certificado para cada nodo agente antes de poder tomar sus manifest.  El despliegue de HTCondor estara dado posteriormente a la creacion de las maquinas virtuales. Puppet sera el encargado de ejecutar la configuracion de HTCondor en 2 de los 3 nodos creados con anterioridad. Esto se explicara en el transcurso del readme.

Las recomendaciones a tener en cuenta para que este entorno funcione correctamente son los siguientes.

* La maquina puppet master tendra el nombre de puppet y los nodos clientes tendran el nombre de puppetagent1 y puppetagent2.   
* Para establecer un password para el usuario root basta con digitar el comando (sudo passwd root).
* La maquina que sera puppet master debera tener como minimo 3 gigas de Ram, debido a que en la inicializacion del proceso (puppetserver.service) en su archivo de   configuracion viene por defecto para uso de 2 gigas de ram despues de su instalacion. Esto se puede modificar en su propio archivo de configuracion ubicado en     /etc/puppetlabs/puppet/puppet.conf. Puppet Server es el software que se instala una unica ves en el puppet master y es el encargado de hacer cumplir el rol de     nodo master.  Para uso de este despliegue se han otorgado estas 3 gigas de Ram a la maquina virtual puppet master y asi evitar problemas en el despliegue.
        

A continuacion se muestra el archivo Vagrantfile, exponiendo los scripts utilizados y el aprovisionamiento para cada maquina desarrollado.

# Instalacion de puppet-server y puppet-agent en la maquina master de puppet

El box utilizado para las 3 maquinas virtuales sera /ubuntu/xenial64.

* Se actualizan los repositorios de la maquina.        

        sudo apt-get -y update
        sudo apt-get -y upgrade    

* Sincronizar zona horaria en cada nodo del cluster. Si surge un problema de sincronizacion de tiempo, los certificados podran aparecer vencidos, existiendo discrepancias entre  el Puppet master y los Puppet agent nodes. 

        sudo timedatectl set-timezone "America/Bogota"
        sudo hostnamectl set-hostname puppet               

#### Instalacion de puppetserver y puppetagent en la maquina master

* Agregamos los repositorios de Puppet desde el sitio oficial de Puppet, actualizamos los repositorios de nuestro box y posteriormente ejecutamos su instalacion.

        sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
        sudo dpkg -i puppetlabs-release-pc1-xenial.deb
        sudo apt-get -y update
        sudo apt-get -y install puppet-agent
        sudo apt-get -y install puppetserver

* Nos asegurarnos de que el puppetserver.service y el firewall permitan que el proceso JVM de Puppet Server acepte conexiones en el puerto 8140. Además, los clientes puppet deben poder realizar la conexión al maestro en ese mismo puerto.

        sudo ufw allow 8140   

* Finalizada la instalacion iniciamos el servicio de puppetserver.service y dejamos habilitado el servicio, para cada momento que la maquina inice. Es de considerar que esta maquina es la encargada de administrar los clientes puppet y velara  por la configuracion establecida para cada uno.

        sudo systemctl  start   puppetserver.service
        sudo systemctl  enable  puppetserver.service

# Archivos Manifest 

Los archivos manifest de Puppet son ficheros en donde se declaran todos los recursos, servicios, o paquetes que deben verificarse y cambiarse. Cada manifest tendra el estado deseado para cada cliente Puppet y el puppet master se encargara de efectuar y supervisar correctamente esa configuracion. Los archivos manifest de Puppet se crean en la maquina Puppet master y tienen la extensión .pp.

Estos archivos son compuestos por las siguientes carpetas. 

 * Files: Son los archivos de texto sin formato que se deben importar y colocar en la ubicación de destino. 
 * Resources: Los recursos representan los elementos que necesitamos evaluar o cambiar. Los recursos pueden ser archivos, paquetes, etc. 
 * Node definition: Es un bloque de código en Puppet donde se define toda la información y definición del nodo del cliente. 
 * Templates: Los templates se utilizan para crear archivos de configuración en los nodos y se pueden reutilizar más tarde. 
 * Classes: Las classes son lo que utilizamos para agrupar los diferentes tipos de recursos.
        
Teniendo en cuenta lo anterior se exponen las recomendaciones para que el manifest de HTCondor sea tomado correctamente por puppet.

#### Indicaciones en la maquina puppet master

* Se guardan los manifest subido al repositorio en la carpeta manifest de puppetserver. Esta carpeta se encuentra ubicada en                                         /etc/puppetlabs/puppet/code/environment/production/manifest.
* La carpeta con el nombre "modules" ubicada en el repositorio, sera reemplazada con el "modules" de puppet server en la ubicacion                                   /etc/puppetlabs/puppet/code/environment/production/modules. Esta carpeta contiene los files necesarios para configurar el entorno de HTCondor.
        
#### Indicaciones en los clientes Puppet

Teniendo los manifest y files necesarios alojados en el servidor master de puppet, se procede a pedir la configuracion por parte de cada nodo cliente al puppet  master. El comando a correr es el siguiente.
        
        sudo /opt/puppetlabs/puppet/bin/puppet agent -t 
       
Inmediatamente el cliente puppet realizara una peticion a traves del puerto 8140 al puppet server y el puppet server, en funcion del manifest añadido en sus carpetas, procedera a realizar el despliegue de la configuracion para dicho nodo. Esto aplica para todo los dos nodos de este entorno, obteniendo como resultado el despliegue y configuracion del pool de HTCondor. El nodo puppetagent1 actuara como el master de HTCondor y el puppetagent2 sera un worker del pool de      HTCondor. 

# Firmar certificados de los clientes puppet

Cuando el software Puppet se ejecuta por primera vez en cualquier cliente Puppet, genera un certificado y envía la solicitud de firma del certificado al Puppet Master. Antes de que el servidor Puppet pueda comunicarse y controlar los nodos de agente, debe firmar el certificado de ese nodo de agente en particular. 
Este proceso ya se encuentra establecido en el despliegue del Vagrant file, dejando solamente la firma del certificado por parte de Puppet master.

        sudo /opt/puppetlabs/puppet/bin/puppet cert list --all 
        systemctl restart puppetserver.service


# Instalacion de puppet-agent en los nodos clientes puppet

* Actualizacion del box y sincronizacion de zona horaria

        sudo apt-get -y update
        sudo apt-get -y upgrade    
        sudo timedatectl set-timezone "America/Bogota"
        

* Instalacion de puppetagent

        sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
        sudo dpkg -i puppetlabs-release-pc1-xenial.deb
        sudo apt-get -y update
        sudo apt-get -y install puppet-agent


* Activacion de servicios puppet, con el fin de que cada cliente puppet logre generar una conexion con el puppet master.

        sudo systemctl start    puppet.service
        sudo systemctl enable   puppet.service

# Creacion y configuracion de las maquinas virtuales.

En el proceso anterior se muestras los scripts para dotar las maquinas con los softwares necesarios. A continuacion se muestra la configuracion de cada maquina virtual creada:

Como se menciono anteriormente, inicialmente se crean las maquina clientes puppet y luego el puppet master.

* Nodo cliente puppet 1 

        Vagrant.configure('2') do |config|
        config.vm.define "puppetagent1" do |puppetagent1|
  
        #Box a utilizar, previamente descargado
        puppetagent1.vm.box = 'ubuntu/xenial64'

* Hostname
        
        puppetagent1.vm.hostname = "puppetagent1"

* IP privada
        
        puppetagent1.vm.network 'private_network', ip: '192.168.20.21'

* Aprovisionamiento de maquina 

        puppetagent1.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent1"
        puppetagent1.vm.provision "shell", inline:  $script2, privileged: true 
        puppetagent1.vm.provision "shell", path:   "añadir_hostname.sh", privileged: true
        puppetagent1.vm.provision "shell", path:   "Puppet.conf_agentes.sh", privileged: true
        puppetagent1.vm.provision "shell", inline: "sudo /opt/puppetlabs/bin/puppet agent --test" 

* Reemplazar el archivo hosts con el script "añadir hostname"

Este archivo ubicado en /etc/hosts permite apuntar un nombre de dominio de nuestra elección a un servidor en concreto, a un ordenador en red local o a nuestra misma máquina a través de su IP, alias o dominio. Este archivo se modifica por medio del script "añadir_hostname" el cual permite reemplazar el archivo propio de la maquina virtual creada, con un archivo hosts creado por nosotros.

* Designar quien es el puppet master en las maquinas clientes de puppet        

La arquitectura que maneja Puppet (master-agent), implica que cada cliente puppet debe conocer de antemano quien sera el master. Esta configuracion se automatiza por medio del script "Puppet.conf_agentes.sh", el cual escribe en el archivo de configuracion del cliente Puppet, quien es puppet master. 

        puppetagent1.vm.provision "shell", path: "Puppet.conf_agentes.sh", privileged: true    
         
* Nodo de trabajo2

        config.vm.define "puppetagent2" do |puppetagent2|
  
* Box a utilizar, previamente descargado

        puppetagent2.vm.box = 'ubuntu/xenial64'

* Hostname

        puppetagent2.vm.hostname = "puppetagent2"

* IP privada

        puppetagent2.vm.network 'private_network', ip: '192.168.20.22'

* Aprovisionamiento de maquina 

        puppetagent2.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent2"
        puppetagent2.vm.provision "shell", inline:  $script2, privileged: true
        puppetagent2.vm.provision "shell", path:   "añadir_hostname.sh",     privileged: true
        puppetagent2.vm.provision "shell", path:   "Puppet.conf_agentes.sh", privileged: true
        puppetagent2.vm.provision "shell", inline: "sudo /opt/puppetlabs/bin/puppet agent --test"    
    
    
* Maquina puppet master

        config.vm.define "puppet" do |puppet|
    
* Box a utilizar, previamente descargado
       
       puppet.vm.box = 'ubuntu/xenial64'
* Hostname
       
       puppet.vm.hostname = "puppet"

* IP privada
        
        puppet.vm.network 'private_network', ip: '192.168.20.23'


* Aprovisionamiento de maquina 
        
        puppet.vm.provision "shell", inline:  $script, privileged: true
        puppet.vm.provision "shell", path:    "añadir_hostname.sh",  privileged: true
        
    
* Personalizar maquina virtual    
        
        puppet.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", 3072]   
# Pasos para ejecución

Ejecutar el script `iniciar.sh` 

    sh iniciar.sh


Finalizada la ejecucion del script, ejecutar todo lo relacionado con Puppet en modo root. Copiar las carpetas "modules" y "manifest" de /vagrant a /etc/puppetlabs/code/enviroment/production

    sudo cp -r /vagrant/modules/condor /etc/puppetlabs/code/environments/production/modules/
    sudo cp -r /vagrant/manifests/ /etc/puppetlabs/code/environments/production/

Configurar la certificacion de clientes puppet por parte de puppet master:


    sudo /opt/puppetlabs/bin/puppet cert sign --all
    sudo systemctl restart puppetserver.service

Ahora nos dirigimos al `puppetagent1` y verificamos su funcionamiento con el puppetmaster


    vagrant ssh puppetagent1
    sudo /opt/puppetlabs/puppet/bin/puppet agent -t

Por ultimo nos dirigimos al `puppetagent2` y realizamos el proceso anterior. 

    vagrant ssh puppetagent2
    sudo /opt/puppetlabs/puppet/bin/puppet agent -t

Nos aseguramos que el despliegue de HTCondor se encuentre correctamente configurado, dirigiendonos nuevamente al `puppetagent1`


    vagrant ssh puppetagent1
    condor_status 
    condor_q
    
Con los comandos descritos anteriormente se observa el pool de HTCondor y la información relaciona con trabajos en la cola de tareas, respectivamente.


# Explicacion del fichero Vagrant file, con relacion a la instalacion y configuracion de Puppet por medio de Vagrant

El procedimiento a realizar esta dado por el despliegue y configuracion de Puppet. Posteriormente se anexan los manifest, files y scripts que soportan el despliegue y configuración de HTCondor a través de Puppet. 

El entorno en el que se desarrolla este proyecto esta dado por 3 maquinas virtuales, generadas con Vagrant (herramienta para la creación y configuración de entornos de desarrollo virtualizados). Se tendran dos arquitecturas desplegadas con la ayuda de Vagrant, el cual sera master-agent, perteneciente al gestor de configuracion Puppet y al finalizar el despliegue y configuracion de Puppet, se tendra otra arquitectura perteneciente a HTCondor (master-worker), la cual nos la facilitara el gestor de configuracion Puppet. Estas tres maquinas virtuales tendran como nombre: 

* puppet, quien asume el rol de Puppet master, 

* puppetagent1 y puppetagent2, quienes seran las maquinas encargadas de ser dotadas por un gestor de cola de tareas, a traves de Puppet y a su ves seran             clientes puppet.

Finalizado el despliegue de Puppet, se debera certificar los clientes Puppet de forma manual. El Puppet master debe aprobar una solicitud de certificado para cada nodo agente antes de poder tomar sus manifest.  El despliegue de HTCondor estara dado posteriormente a la creacion de las maquinas virtuales. Puppet sera el encargado de ejecutar la configuracion de HTCondor en 2 de los 3 nodos creados con anterioridad. Esto se explicara en el transcurso del readme.

Las recomendaciones a tener en cuenta para que este entorno funcione correctamente son los siguientes.

* La maquina puppet master tendra el nombre de puppet y los nodos clientes tendran el nombre de puppetagent1 y puppetagent2.   
* Para establecer un password para el usuario root basta con digitar el comando (sudo passwd root).
* La maquina que sera puppet master debera tener como minimo 3 gigas de Ram, debido a que en la inicializacion del proceso (puppetserver.service) en su archivo de   configuracion viene por defecto para uso de 2 gigas de ram despues de su instalacion. Esto se puede modificar en su propio archivo de configuracion ubicado en     /etc/puppetlabs/puppet/puppet.conf. Puppet Server es el software que se instala una unica ves en el puppet master y es el encargado de hacer cumplir el rol de     nodo master.  Para uso de este despliegue se han otorgado estas 3 gigas de Ram a la maquina virtual puppet master y asi evitar problemas en el despliegue.
        

A continuacion se muestra el archivo Vagrantfile, exponiendo los scripts utilizados y el aprovisionamiento para cada maquina desarrollado.

# Instalacion de puppet-server y puppet-agent en la maquina master de puppet

El box utilizado para las 3 maquinas virtuales sera /ubuntu/xenial64.

* Se actualizan los repositorios de la maquina.        

        sudo apt-get -y update
        sudo apt-get -y upgrade    

* Sincronizar zona horaria en cada nodo del cluster. Si surge un problema de sincronizacion de tiempo, los certificados podran aparecer vencidos, existiendo discrepancias entre  el Puppet master y los Puppet agent nodes. 

        sudo timedatectl set-timezone "America/Bogota"
        sudo hostnamectl set-hostname puppet               

#### Instalacion de puppetserver y puppetagent en la maquina master

* Agregamos los repositorios de Puppet desde el sitio oficial de Puppet, actualizamos los repositorios de nuestro box y posteriormente ejecutamos su instalacion.

        sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
        sudo dpkg -i puppetlabs-release-pc1-xenial.deb
        sudo apt-get -y update
        sudo apt-get -y install puppet-agent
        sudo apt-get -y install puppetserver

* Nos asegurarnos de que el puppetserver.service y el firewall permitan que el proceso JVM de Puppet Server acepte conexiones en el puerto 8140. Además, los clientes puppet deben poder realizar la conexión al maestro en ese mismo puerto.

        sudo ufw allow 8140   

* Finalizada la instalacion iniciamos el servicio de puppetserver.service y dejamos habilitado el servicio, para cada momento que la maquina inice. Es de considerar que esta maquina es la encargada de administrar los clientes puppet y velara  por la configuracion establecida para cada uno.

        sudo systemctl  start   puppetserver.service
        sudo systemctl  enable  puppetserver.service

# Archivos Manifest 

Los archivos manifest de Puppet son ficheros en donde se declaran todos los recursos, servicios, o paquetes que deben verificarse y cambiarse. Cada manifest tendra el estado deseado para cada cliente Puppet y el puppet master se encargara de efectuar y supervisar correctamente esa configuracion. Los archivos manifest de Puppet se crean en la maquina Puppet master y tienen la extensión .pp.

Estos archivos son compuestos por las siguientes carpetas. 

 * Files: Son los archivos de texto sin formato que se deben importar y colocar en la ubicación de destino. 
 * Resources: Los recursos representan los elementos que necesitamos evaluar o cambiar. Los recursos pueden ser archivos, paquetes, etc. 
 * Node definition: Es un bloque de código en Puppet donde se define toda la información y definición del nodo del cliente. 
 * Templates: Los templates se utilizan para crear archivos de configuración en los nodos y se pueden reutilizar más tarde. 
 * Classes: Las classes son lo que utilizamos para agrupar los diferentes tipos de recursos.
        
Teniendo en cuenta lo anterior se exponen las recomendaciones para que el manifest de HTCondor sea tomado correctamente por puppet.

#### Indicaciones en la maquina puppet master

* Se guardan los manifest subido al repositorio en la carpeta manifest de puppetserver. Esta carpeta se encuentra ubicada en                                         /etc/puppetlabs/puppet/code/environment/production/manifest.
* La carpeta con el nombre "modules" ubicada en el repositorio, sera reemplazada con el "modules" de puppet server en la ubicacion                                   /etc/puppetlabs/puppet/code/environment/production/modules. Esta carpeta contiene los files necesarios para configurar el entorno de HTCondor.
        
#### Indicaciones en los clientes Puppet

Teniendo los manifest y files necesarios alojados en el servidor master de puppet, se procede a pedir la configuracion por parte de cada nodo cliente al puppet  master. El comando a correr es el siguiente.
        
        sudo /opt/puppetlabs/puppet/bin/puppet agent -t 
       
Inmediatamente el cliente puppet realizara una peticion a traves del puerto 8140 al puppet server y el puppet server, en funcion del manifest añadido en sus carpetas, procedera a realizar el despliegue de la configuracion para dicho nodo. Esto aplica para todo los dos nodos de este entorno, obteniendo como resultado el despliegue y configuracion del pool de HTCondor. El nodo puppetagent1 actuara como el master de HTCondor y el puppetagent2 sera un worker del pool de      HTCondor. 

# Firmar certificados de los clientes puppet

Cuando el software Puppet se ejecuta por primera vez en cualquier cliente Puppet, genera un certificado y envía la solicitud de firma del certificado al Puppet Master. Antes de que el servidor Puppet pueda comunicarse y controlar los nodos de agente, debe firmar el certificado de ese nodo de agente en particular. 
Este proceso ya se encuentra establecido en el despliegue del Vagrant file, dejando solamente la firma del certificado por parte de Puppet master.

        sudo /opt/puppetlabs/puppet/bin/puppet cert list --all 
        systemctl restart puppetserver.service


# Instalacion de puppet-agent en los nodos clientes puppet

* Actualizacion del box y sincronizacion de zona horaria

        sudo apt-get -y update
        sudo apt-get -y upgrade    
        sudo timedatectl set-timezone "America/Bogota"
        

* Instalacion de puppetagent

        sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
        sudo dpkg -i puppetlabs-release-pc1-xenial.deb
        sudo apt-get -y update
        sudo apt-get -y install puppet-agent


* Activacion de servicios puppet, con el fin de que cada cliente puppet logre generar una conexion con el puppet master.

        sudo systemctl start    puppet.service
        sudo systemctl enable   puppet.service

# Creacion y configuracion de las maquinas virtuales.

En el proceso anterior se muestras los scripts para dotar las maquinas con los softwares necesarios. A continuacion se muestra la configuracion de cada maquina virtual creada:

Como se menciono anteriormente, inicialmente se crean las maquina clientes puppet y luego el puppet master.

* Nodo cliente puppet 1 

        Vagrant.configure('2') do |config|
        config.vm.define "puppetagent1" do |puppetagent1|
  
        #Box a utilizar, previamente descargado
        puppetagent1.vm.box = 'ubuntu/xenial64'

* Hostname
        
        puppetagent1.vm.hostname = "puppetagent1"

* IP privada
        
        puppetagent1.vm.network 'private_network', ip: '192.168.20.21'

* Aprovisionamiento de maquina 

        puppetagent1.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent1"
        puppetagent1.vm.provision "shell", inline:  $script2, privileged: true 
        puppetagent1.vm.provision "shell", path:   "añadir_hostname.sh", privileged: true
        puppetagent1.vm.provision "shell", path:   "Puppet.conf_agentes.sh", privileged: true
        

* Reemplazar el archivo hosts con el script "añadir hostname"

Este archivo ubicado en /etc/hosts permite apuntar un nombre de dominio de nuestra elección a un servidor en concreto, a un ordenador en red local o a nuestra misma máquina a través de su IP, alias o dominio. Este archivo se modifica por medio del script "añadir_hostname" el cual permite reemplazar el archivo propio de la maquina virtual creada, con un archivo hosts creado por nosotros.

* Designar quien es el puppet master en las maquinas clientes de puppet        

La arquitectura que maneja Puppet (master-agent), implica que cada cliente puppet debe conocer de antemano quien sera el master. Esta configuracion se automatiza por medio del script "Puppet.conf_agentes.sh", el cual escribe en el archivo de configuracion del cliente Puppet, quien es puppet master. 

        puppetagent1.vm.provision "shell", path: "Puppet.conf_agentes.sh", privileged: true    
         
* Nodo de trabajo2

        config.vm.define "puppetagent2" do |puppetagent2|
  
* Box a utilizar, previamente descargado

        puppetagent2.vm.box = 'ubuntu/xenial64'

* Hostname

        puppetagent2.vm.hostname = "puppetagent2"

* IP privada

        puppetagent2.vm.network 'private_network', ip: '192.168.20.22'

* Aprovisionamiento de maquina 

        puppetagent2.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent2"
        puppetagent2.vm.provision "shell", inline:  $script2, privileged: true
        puppetagent2.vm.provision "shell", path:   "añadir_hostname.sh",     privileged: true
        puppetagent2.vm.provision "shell", path:   "Puppet.conf_agentes.sh", privileged: true
            
    
    
* Maquina puppet master

        config.vm.define "puppet" do |puppet|
    
* Box a utilizar, previamente descargado
       
       puppet.vm.box = 'ubuntu/xenial64'
* Hostname
       
       puppet.vm.hostname = "puppet"

* IP privada
        
        puppet.vm.network 'private_network', ip: '192.168.20.23'


* Aprovisionamiento de maquina 
        
        puppet.vm.provision "shell", inline:  $script, privileged: true
        puppet.vm.provision "shell", path:    "añadir_hostname.sh",  privileged: true
        
    
* Personalizar maquina virtual    
        
        puppet.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", 3072]   
