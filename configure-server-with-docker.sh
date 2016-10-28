#!/bin/bash -e

function error {
  echo -e "\n\e[1;31m$1\e[0m\n"
}

function log {
  echo $1
}

function info {
  echo -e "\n\e[0;32m$1\e[0m\n"
}

function pause {
  read -p $'\n\e[1;34m'"$*"$' Pessione [Enter] para continuar...\e[0m'
}

function verify_ubuntu {
  if ! [ -f /etc/lsb-release ]; then
    error "Seu sistema operacional atual não é Ubuntu, infelizmente não tenho conhecimento para continuar com a configuração. Sorry :("
    exit 1;
  fi
}

function verify_root {
  if [ "$(id -u)" != "0" ]; then
     error "Infelizmente não posso continuar :~, preciso que você confie em mim e me dê permissão de root (eu sei, eu sei, mas prometo não fazer coisas ruins)"
     exit 1;
  fi
}

function system_upgrade {
  pause "Vou atualizar o seu sistema."

  apt-get -y update
  apt-get -y upgrade
}

function basic_packages {
  pause "Vou instalar alguns pacotes básicos."
  apt-get install -y \
        curl \
        htop \
        vim \
        git

  curl -sSL https://get.docker.com/gpg | sudo apt-key add -
  curl -sSL https://get.docker.com/ | sh
  curl -L "https://github.com/docker/compose/releases/download/1.8.1/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
}

function add_user_administrador {
  password=`date +%s | sha256sum | base64 | head -c 16`
  pause "Vou adicionar um usuário SUDO para você administrar o sistema, escolha uma boa senha. Dica de senha $password"
  adduser administrador
  adduser administrador sudo
  usermod -a -G docker administrador
  sudo -u administrador ssh-keygen -t rsa

  echo "ssh-rsa $PUBLIC_KEY_ADMINISTRADOR" > /home/administrador/.ssh/authorized_keys
  chown administrador.administrador /home/administrador/.ssh/authorized_keys
  chmod -rwx /home/administrador/.ssh/authorized_keys
  chmod u+rw /home/administrador/.ssh/authorized_keys
}

function configure_timezone_to_brazil {
  pause "Estou configurando seu relógio, gosto das horas Brasileiras..."
  ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
}

function configure_locale_brazil {
  pause "Vou configurar seu locale para pt_BR, seria muito legal se só existisse um locale, sei que você já perdeu bastante tempo com isso :("
  locale-gen pt_BR.UTF-8
}

function configure_ssh {
  pause "Vou configurar seu servidor SSH, isso envolve, trocar a porta padrão para 2222, desabilitar login como root (Ufa!), desabilitar login com senha (somente via troca de chaves)"
  sed "s/Port .*/Port 2222/" /etc/ssh/sshd_config > /tmp/sshd
  sed -i "s/.*PermitRootLogin .*/PermitRootLogin no/" /tmp/sshd
  sed -i "s/.*PasswordAuthentication .*/PasswordAuthentication no/" /tmp/sshd

  cp /tmp/sshd /etc/ssh/sshd_config

  cat /etc/ssh/sshd_config
}

function disable_root {
  pause "Agora vou desabilitar por completo o login como root \o"
  passwd -l root
}

function swap {
  pause "Vou adicionar SWAP para você"
  total_memory=$(( `grep MemTotal /proc/meminfo | awk '{print $2}'` / 1024 ))
  swap_size=$(( total_memory * 2 ))
  read -p "Eu acho que sua memória atual é de $total_memory MB, e por isso irei criar SWAP de tamanho $swap_size MB, posso? (S/n)" answer
  if [[ $answer != "S" && $answer != "s" && $answer != "" ]]; then
    read -p "Certo... Qual é o tamannho (em MB) da SWAP que eu devo criar então sabidão?" swap_size
  fi

  info "Irei criar SWAP no tamanho de $swap_size MB"
  fallocate -l "$swap_size"MB /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
  echo "vm.swappiness=10" >> /etc/sysctl.conf
}

function configure_new_relic {
  pause "New Relic presente nesta obra!"

  echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list
  wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
  apt-get update
  apt-get install newrelic-sysmond
  usermod -a -G docker newrelic
  nrsysmond-config --set license_key=$NEW_RELIC_KEY
  /etc/init.d/newrelic-sysmond start
}

function enable_automatic_security_upgrade {
  pause "Como eu sou um ser muito legal, vou habilitar para você as atualizações automáticas de segurança"
  dpkg-reconfigure -plow unattended-upgrades
}

function firewall {
  read -p "Agora, vamos nos proteger, quais portas você deseja deixar liberadas? (2222 80)? " ports
  if [[ $ports == "" ]]; then
    ports="2222 80"
  fi
  apt-get install -y iptables-persistent

  iptables -F
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  for port in $ports
  do
    iptables -A INPUT -p tcp --dport $port -j ACCEPT
  done
  iptables -I INPUT 1 -i lo -j ACCEPT
  iptables -A INPUT -i docker0 -j ACCEPT
  iptables -P INPUT DROP

  iptables-save > /etc/iptables/rules.v4

  pause "Firewall está configurado, somente as portas $ports estão liberadas para serem acessadas externamente, o resto está bloqueado."
}

function clean {
  pause "Sempre que eu trabalho, eu costumo sujar algumas coisas, por isso vou fazer uma boa limpeza"
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

function reboot {
  pause "Agora, vodê pode reiniciar seu servidor e tudo estará funcionando (Espero que assim seja). Vou sentir saudades..."
}

pause "Olá, eu sou o Scribot e vou guiar você durante todo o processo de configuração."

verify_ubuntu

verify_root

system_upgrade

basic_packages

add_user_administrador

configure_timezone_to_brazil

configure_locale_brazil

configure_ssh

disable_root

swap

configure_new_relic

enable_automatic_security_upgrade

firewall

clean

reboot
