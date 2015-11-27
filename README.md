# Scripts
Scripts to optimize our (developer) work

## configure-server-with-docker.sh
Basic configuration for a server that will run docker (Just for operating system based on Debian)
* Upgrade operating system
* Install basic packages: curl, htop, vim, git, docker
* Add sudo user "administrador"
* Add **$PUBLIC_KEY_ADMINISTRADOR** to authorized_keys in the "administrador" account
* Configure timezone to Brazil
* Configure locale to Brazil
* Configure SSH server for running in 2222 port
* Disable access with password in the SSH server
* Disable root access in the SSH server
* Create swap
* Add New Relic with **$NEW_RELIC_KEY** key
* Enable automatic security upgrades
* Configure firewal