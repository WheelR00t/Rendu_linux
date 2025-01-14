#!/bin/bash

echo "Mise à jour"
sudo apt update && sudo apt upgrade -y

# Installation 
echo "Installation"
sudo apt install -y apache2 mysql-server php php-cli php-fpm php-mysql libapache2-mod-php \
    curl unzip libxml2-dev libzip-dev php-zip php-gd php-curl php-intl php-bz2 php-mbstring \
    php-xml php-imagick php-apcu certbot python3-certbot-apache

# Configuration d'Apache
echo "Configuration d'Apache..."
sudo a2enmod rewrite headers env dir mime ssl
sudo systemctl restart apache2

# Sécurisation d'Apache
echo "Sécurisation d'Apache..."
sudo a2dismod status
sudo a2dismod userdir
sudo sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-enabled/security.conf
sudo sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-enabled/security.conf
sudo systemctl restart apache2

# Sécurisation de SSH (Changement de port et désactivation de l'authentification par mot de passe)
echo "Sécurisation de SSH..."
sudo sed -i 's/#Port 22/Port 2200/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

echo "Installation de Nextcloud..."
cd /var/www
sudo curl -LO https://download.nextcloud.com/server/releases/nextcloud-25.0.2.zip
sudo unzip nextcloud-25.0.2.zip
sudo chown -R www-data:www-data /var/www/nextcloud
sudo chmod -R 755 /var/www/nextcloud

echo "Configuration de la BDD"
sudo mysql -u root -e "CREATE DATABASE nextcloud;"
sudo mysql -u root -e "CREATE USER 'nextclouduser'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextclouduser'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

echo "Configuration d'Apache"
sudo bash -c 'cat > /etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud
    ServerName nextcloud.example.com
    <Directory /var/www/nextcloud>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF'

echo "Activation du site"
sudo a2ensite nextcloud.conf
sudo systemctl reload apache2

# Sécurisation du dossier Nextcloud
echo "Sécurisation du dossier Nextcloud..."
sudo sed -i 's/Options Indexes FollowSymLinks/Options -Indexes FollowSymLinks/' /etc/apache2/sites-available/nextcloud.conf
sudo systemctl reload apache2

# Configuration du pare-feu UFW
echo "Configuration du pare-feu UFW..."
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'
sudo ufw enable

# Vérification de l'installation
echo "Vérification de l'installation."
sudo systemctl restart apache2
sudo systemctl restart mysql

echo "Installation et sécurisation terminées. Vous pouvez maintenant accéder à Nextcloud"
