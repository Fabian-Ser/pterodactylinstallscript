#!/bin/bash
GEBRUIK_SSL=false
echo "Installatie voorbereiden..."
apt update > /dev/null 2>&1
sudo apt-get install nano > /dev/null 2>&1
service apache2 stop > /dev/null 2>&1
sudo apt-get install apt-transport-https > /dev/null 2>&1
echo "----------------------------------"
echo "Welkom bij de install script van MC-Node, voordat we beginnen hebben we wat informatie nodig"
echo "----------------------------------"
echo "Typ uw gewenste panel naam (FQDN) in"
read FQDN
echo "Wilt u SSL zetten op dit domein? (IP's KUNNEN GEEN SSL HEBBEN) (y/n)"
read GEBRUIK_SSL_KEUZE
if [ "$GEBRUIK_SSL_KEUZE" == "y"]; then
    GEBRUIK_SSL=true
elif [ "$GEBRUIK_SSL_KEUZE" == "Y"]; then
    GEBRUIK_SSL=true
elif [ "$GEBRUIK_SSL_KEUZE" == "J"]; then
    GEBRUIK_SSL=true
elif [ "$GEBRUIK_SSL_KEUZE" == "Ja"]; then
    GEBRUIK_SSL=true
elif [ "$GEBRUIK_SSL_KEUZE" == "ja"]; then
    GEBRUIK_SSL=true
elif [ "$GEBRUIK_SSL_KEUZE" == "yes"]; then 
    GEBRUIK_SSL=true
elif [ "$GEBRUIK_SSL_KEUZE" == "Yes"]; then 
    GEBRUIK_SSL=true
elif [ "$GEBRUIK_SSL_KEUZE" == "YES"]; then 
    GEBRUIK_SSL=true
elif [ "$GEBRUIK_SSL_KEUZE" == "NO"]; then 
    GEBRUIK_SSL=false
elif [ "$GEBRUIK_SSL_KEUZE" == "No"]; then 
    GEBRUIK_SSL=false
elif [ "$GEBRUIK_SSL_KEUZE" == "no"]; then 
    GEBRUIK_SSL=false
elif [ "$GEBRUIK_SSL_KEUZE" == "n"]; then 
    GEBRUIK_SSL=false
elif [ "$GEBRUIK_SSL_KEUZE" == "N"]; then 
    GEBRUIK_SSL=false
elif [ "$GEBRUIK_SSL_KEUZE" == "nee"]; then 
    GEBRUIK_SSL=false
elif [ "$GEBRUIK_SSL_KEUZE" == "Nee"]; then 
    GEBRUIK_SSL=false
else
    print_error "Antwoord voldoet niet aan de eisen, er wordt geen SSL gebruikt."
    exit 1
fi
echo "Typ uw gewenste MYSQL Database Wachtwoord in"
read MYSQL_PASSWORD
echo "[x] De installatie is begonnen, dit duurt 5-10 minuten, zodra de installer iets vraagt, druk op enter."
apt -y install software-properties-common curl > /dev/null 2>&1
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
add-apt-repository -y ppa:chris-lea/redis-server > /dev/null 2>&1
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash > /dev/null 2>&1
apt update > /dev/null 2>&1
apt-add-repository universe > /dev/null 2>&1
apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip mariadb-server nginx tar unzip git redis-server > /dev/null 2>&1
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
echo "[x] Panel files aan het installeren..."
mkdir -p /var/www/pterodactyl > /dev/null 2>&1
cd /var/www/pterodactyl > /dev/null 2>&1
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.15/panel.tar.gz > /dev/null 2>&1
tar --strip-components=1 -xzvf panel.tar.gz > /dev/null 2>&1
chmod -R 755 storage/* bootstrap/cache/ > /dev/null 2>&1
echo "[x] Database aan het installeren..."
echo "Bij het vragen van een wachtwoord, gewoon op enter drukken!"
mysql -u root -p -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -u root -p -e "CREATE DATABASE panel;"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
mysql -u root -p -e "FLUSH PRIVILEGES;"
echo "[x] .ENV file aan het configureren"
echo "Bij het vragen van dingen, gewoon op enter drukken!"
cp .env.example .env > /dev/null 2>&1
composer install --no-dev --optimize-autoloader > /dev/null 2>&1
sed -i -e "s|APP_TIMEZONE=America/New_York|APP_TIMEZONE=Europe/Amsterdam|g" /var/www/pterodactyl/.env
sed -i -e "s|APP_LOCALE=en|APP_LOCALE=nl|g" /var/www/pterodactyl/.env
sed -i -e "S|DB_PASSWORD=|DB_PASSWORD=${MYSQL_PASSWORD}|g" /var/www/pterodactyl/.env
if [GEBRUIK_SSL=true]; then
echo "APP_URL=https://${FQDN}" >> /var/www/pterodactyl/.env
elif [GEBRUIK_SSL=false]; then
echo "APP_URL=http://${FQDN}" >> /var/www/pterodactyl/.env
fi
php artisan key:generate --force > /dev/null 2>&1
php artisan p:environment:setup
php artisan p:environment:database
php artisan p:environment:mail
echo "[x] Files in de database aan het zetten..."
php artisan migrate --seed > /dev/null 2>&1
echo "[x] Maak een nieuwe user aan"
php artisan p:user:make 
echo "[x] Permissies aan het instellen..."
cd /var/www/pterodactyl && chown -R www-data:www-data * > /dev/null 2>&1
echo "[x] Pterodactyl opstarten..."
curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/configs/pteroq.service > /dev/null 2>&1
sudo systemctl enable --now redis-server > /dev/null 2>&1
sudo systemctl enable --now pteroq.service > /dev/null 2>&1
if [GEBRUIK_SSL=true]; then
systemctl stop nginx > /dev/null 2>&1
service nginx stop > /dev/null 2>&1
service apache2 stop > /dev/null 2>&1
sudo add-apt-repository ppa:certbot/certbot > /dev/null 2>&1
sudo apt update > /dev/null 2>&1
sudo apt install certbot > /dev/null 2>&1
echo "[x] SSL configuratie (Selecteer 1, voer daarna een email in, typ A, typ N)"
certbot certonly -d ${FQDN}
sleep 10
echo "[x] Webserver wordt geinstalleerd..."
curl -o /etc/nginx/conf.d/pterodactyl.conf https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/configs/nginx_ssl.conf
sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
elif [GEBRUIK_SSL=false]; then
systemctl stop nginx > /dev/null 2>&1
service nginx stop > /dev/null 2>&1
service apache2 stop > /dev/null 2>&1
echo "[x] Webserver wordt geinstalleerd..."
curl -o /etc/nginx/conf.d/pterodactyl.conf https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/configs/nginx.conf
sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
fi
echo "[x] Webserver wordt gestart..."
service nginx start > /dev/null 2>&1
systemctl start nginx > /dev/null 2>&1
systemctl restart nginx > /dev/null 2>&1
echo "[x] Einde van panel installatie, over 20 seconden begint de installatie van de daemon... (DRUK OP CTRL+C ALS ER NOG NIKS IS VERANDERD IN DE BAK!)"
sleep 20 > /dev/null 2>&1
echo "[x] Beginnen van installatie daemon"
echo "[x] Docker wordt geinstalleerd..."
cd  > /dev/null 2>&1
curl -sSL https://get.docker.com/ | CHANNEL=stable bash > /dev/null 2>&1
echo "[x] Docker wordt gestart"
systemctl enable docker > /dev/null 2>&1
echo "[x] NodeJS wordt geinstalleerd..."
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - > /dev/null 2>&1
apt -y install nodejs make gcc g++ > /dev/null 2>&1
echo "[x] Daemon wordt geinstalleerd..."
mkdir -p /srv/daemon /srv/daemon-data > /dev/null 2>&1
cd /srv/daemon > /dev/null 2>&1
curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.12/daemon.tar.gz | tar --strip-components=1 -xzv > /dev/null 2>&1
npm install --only=production > /dev/null 2>&1
curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/VilhelmPrytz/pterodactyl-installer/master/configs/wings.service > /dev/null 2>&1
systemctl enable --now wings > /dev/null 2>&1
systemctl stop wings > /dev/null 2>&1
echo "[x] Daemon is geinstalleerd, enkel moet er nog een node worden aangemaakt op het paneel zodra u deze heeft ingevoegd kunt u de daemon opstarten met systemctl start wings"
echo "----------------------------------"
echo "Bedankt voor het gebruiken van dit script"
echo "Made by Fabian S - System Admin https://mc-node.net"
echo "Thanks to VilhelmPrytz for the configs"
echo "----------------------------------"
