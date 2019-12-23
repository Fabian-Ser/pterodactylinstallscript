#!/bin/bash
USE_SSL=false
echo "[x] Prepairing installation..."
apt update
sudo apt-get install nano
service apache2 stop
sudo apt-get install apt-transport-https
echo "----------------------------------"
echo "Thank you for buying this script!, This script installs pterodactyl 0.8 beta 1."
echo " "
echo "Ubuntu 18.04 is REQUIRED for this installation!"
echo "----------------------------------"
echo "On which domain name should this panel be installed? (FQDN)"
read FQDN
echo "Do you want SSL on this domain? (IPs cannot have SSL!) (y/n)"
read USE_SSL_CHOICE
if [ "$USE_SSL_CHOICE" == "y" ]; then
    USE_SSL=true
elif [ "$USE_SSL_CHOICE" == "Y" ]; then
    USE_SSL=true
elif [ "$USE_SSL_CHOICE" == "J" ]; then
    USE_SSL=true
elif [ "$USE_SSL_CHOICE" == "Ja" ]; then
    USE_SSL=true
elif [ "$USE_SSL_CHOICE" == "ja" ]; then
    USE_SSL=true
elif [ "$USE_SSL_CHOICE" == "yes" ]; then 
    USE_SSL=true
elif [ "$USE_SSL_CHOICE" == "Yes" ]; then 
    USE_SSL=true
elif [ "$USE_SSL_CHOICE" == "YES" ]; then 
    USE_SSL=true
elif [ "$USE_SSL_CHOICE" == "NO" ]; then 
    USE_SSL=false
elif [ "$USE_SSL_CHOICE" == "No" ]; then 
    USE_SSL=false
elif [ "$USE_SSL_CHOICE" == "no" ]; then 
    USE_SSL=false
elif [ "$USE_SSL_CHOICE" == "n" ]; then 
    USE_SSL=false
elif [ "$USE_SSL_CHOICE" == "N" ]; then 
    USE_SSL=false
elif [ "$USE_SSL_CHOICE" == "nee" ]; then 
    USE_SSL=false
elif [ "$USE_SSL_CHOICE" == "Nee" ]; then 
    USE_SSL=false
else
    print_error "Answer not found, no SSL will be used."
    USE_SSL=false
fi
echo "[x] Enter your desired MYSQL Database Password"
read MYSQL_PASSWORD
echo "[x] The installation has started, this takes 5-10 minutes, as soon as the installer asks you something, press enter."
apt -y install software-properties-common curl
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:chris-lea/redis-server
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
apt update
apt-add-repository universe
apt -y install php7.3 php7.3-cli php7.3-gd php7.3-mysql php7.3-pdo php7.3-mbstring php7.3-tokenizer php7.3-bcmath php7.3-xml php7.3-fpm php7.3-curl php7.3-zip mariadb-server nginx tar unzip git redis-server
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
echo "[x] Installing panel software..."
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.8.0-alpha.1/panel.tar.gz
tar --strip-components=1 -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
echo "[x] Installing database..."
echo "[x] By asking a password, press enter"
mysql -u root -p -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -u root -p -e "CREATE DATABASE panel;"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
mysql -u root -p -e "FLUSH PRIVILEGES;"
echo "[x] Editing .ENV"
cp .env.example .env
composer install --no-dev --optimize-autoloader
sed -i -e "s|APP_TIMEZONE=America/New_York|APP_TIMEZONE=Europe/Amsterdam|g" /var/www/pterodactyl/.env
sed -i -e "s|DB_PASSWORD=|DB_PASSWORD=${MYSQL_PASSWORD}|g" /var/www/pterodactyl/.env
if [ "$USE_SSL" == true ]; then
sed -i -e "s|APP_URL=|APP_URL=https://${FQDN}|g" /var/www/pterodactyl/.env
elif [ "$USE_SSL" == false ]; then
sed -i -e "s|APP_URL=|APP_URL=http://${FQDN}|g" /var/www/pterodactyl/.env
fi
echo "[x] Click enter if you need to."
php artisan key:generate --force
echo "[x] Click enter if you need to."
php artisan p:environment:setup
echo "[x] Click enter if you need to."
php artisan p:environment:database
echo "[x] If you want an mail system, then set it, otherwise press enter"
php artisan p:environment:mail
echo "[x] Dropping files in the database..."
php artisan migrate --seed
echo "[x] Create a new user:"
php artisan p:user:make 
echo "[x] Setting folder permissions..."
cd /var/www/pterodactyl && chown -R www-data:www-data *
echo "[x] Starting pterodactyl..."
curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/configs/pteroq.service
sudo systemctl enable --now redis-server
sudo systemctl enable --now pteroq.service
if [ "$USE_SSL" == true ]; then
systemctl stop nginx
service nginx stop
service apache2 stop
sudo add-apt-repository ppa:certbot/certbot
sudo apt update
sudo apt install certbot
echo "[x] SSL Configuration (Select 1, enter your email, choose A, choose N)"
certbot certonly -d ${FQDN}
sleep 10
echo "[x] Staring webserver..."
curl -o /etc/nginx/sites-available/pterodactyl.conf https://raw.githubusercontent.com/Fabian-Ser/pterodactylinstallscript/master/nginxssl.conf
sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
elif [ "$USE_SSL" == false ]; then
systemctl stop nginx
service nginx stop
service apache2 stop
echo "[x] Making webserver ready..."
curl -o /etc/nginx/sites-available/pterodactyl.conf https://raw.githubusercontent.com/Fabian-Ser/pterodactylinstallscript/master/nginxnonssl.conf
sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
fi
echo "[x] Staring webserver..."
service nginx start
systemctl start nginx
systemctl restart nginx
echo "[x] End of panel installation. Starting with the daemon installation in 20 seconds!"
sleep 20
echo "[x] Starting with docker installation..."
cd 
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
echo "[x] Starting docker..."
systemctl enable docker
echo "[x] Daemon wordt geinstalleerd..."
mkdir -p /srv/wings/data/servers /srv/daemon-data
cd /srv/wings
wget https://github.com/pterodactyl/wings/releases/download/v1.0.0-alpha.1/wings
chmod -R 777 /srv/wings
curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/Fabian-Ser/pterodactylinstallscript/master/wings.service
systemctl enable --now wings
systemctl stop wings
echo "[x] Daemon is installed, only a node needs to be created on the panel once you have created the node, you need to insert the config in a file config.yml in the folder /srv/wings after that you can start the daemon with systemctl start wings"
echo "----------------------------------"
echo "Thank you for using this script!"
echo "Made by Fabian S"
echo "----------------------------------"
