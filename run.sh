#!/bin/bash

Install_Task=$1
if [[ $Install_Task == "MySQL" ]]; then
	MYSQL_ROOT_PASS=$2
	echo "given MySQL Password is '$MYSQL_ROOT_PASS'"

	##########################
	# 	  install LAMP
	##########################
	echo "###########################################"
	echo "Starting to install LAMP"
	echo "###########################################"

	# install Apache2
	echo "============================ 1. Installing Apache... ============================"
	apt-get -y update
	apt-get -y install apache2

	# install MySQL
	echo "============================ 1. Installing MySQL... ============================"
	# debconf-set-selections <<< 'mysql-server mysql-server/root_password password "$MYSQL_ROOT_PASS"'
	# debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password "$MYSQL_ROOT_PASS"'
	apt-get -y install mysql-server

	# secure MySQL
	echo "============================ Securing MySQL... ============================"
	[ ! -e /usr/bin/expect ] && { apt-get -y install expect; }

	SECURE_MYSQL=$(expect -c "
	set timeout 10
	spawn mysql_secure_installation

	expect \"Press y|Y for Yes, any other key for No:\" 
	send \"y\r\"
	expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
	send \"0\r\"
	expect \"Enter password for user root:\"
    send \"\r\"
    expect \"Set root password?\"
    send \"y\r\"
	expect \"New password:\"
	send \"${MYSQL_ROOT_PASS}\r\"
	expect \"Re-enter new password:\"
	send \"${MYSQL_ROOT_PASS}\r\"
	expect \"Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :\"
	send \"y\r\"
	expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) : \"
	send \"y\r\"
	expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) : \"
	send \"y\r\"
	expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) : \"
	send \"y\r\"
	expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) : \"
	send \"y\r\"
	expect eof
	")

	echo "$SECURE_MYSQL"

	# install PHP
	echo "============================ 1. Installing PHP... ============================"
	apt-get -y install php libapache2-mod-php php-mysql

	apt-get -y install gcc make autoconf libc-dev pkg-config 
	apt-get -y install php7.2-dev
	apt-get -y install libmcrypt-dev

	apt-get -y install mcrypt

	chmod 777 /etc/apache2/mods-available/dir.conf
	echo "" > /etc/apache2/mods-available/dir.conf
	echo "<IfModule mod_dir.c>
        DirectoryIndex index.php index.cgi index.pl index.html index.xhtml index.htm
</IfModule>" > /etc/apache2/mods-available/dir.conf

elif [[ $Install_Task == "WP" ]]; then
	WP_USER=$2
	WP_PASS=$3
	DB_NAME=$4
	DB_USER=$5
	DB_PASS=$6
	DB_ROOT_PASS=$7
	echo "WP_USER: '$WP_USER', WP_PASS: '$WP_PASS', DB_NAME: '$DB_NAME', DB_USER: '$DB_USER', DB_PASS: '$DB_PASS'"

	##########################
	# 	  install WordPress
	##########################
	echo "###########################################"
	echo "Starting to install WordPress"
	echo "###########################################"

	# Create a MySQL Database and User for WordPress
	echo "============================ Create a MySQL Database and User for WordPress ============================"
	# If /root/.my.cnf exists then it won't ask for root password
	if [ -f /root/.my.cnf ]; then

	    mysql -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
	    mysql -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
	    mysql -e "FLUSH PRIVILEGES;"

	# If /root/.my.cnf doesn't exist then it'll ask for root password   
	else
	    mysql -uroot -p${DB_ROOT_PASS} -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
	    mysql -uroot -p${DB_ROOT_PASS} -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
	    mysql -uroot -p${DB_ROOT_PASS} -e "FLUSH PRIVILEGES;"
	fi

	# Installing Additional PHP Extensions
	echo "============================ Installing Additional PHP Extensions ============================"
	apt update
	apt install php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip
	systemctl restart apache2

	# Adjusting Apache's Configuration to Allow for .htaccess Overrides and Rewrites
	echo "============================ Allow for .htaccess Overrides and Rewrites ============================"
	touch /etc/apache2/sites-available/wordpress.conf
	chmod 777 /etc/apache2/sites-available/wordpress.conf
	echo "<Directory /var/www/wordpress/>
	    AllowOverride All
	</Directory>" > /etc/apache2/sites-available/wordpress.conf
	
	a2enmod rewrite
	apache2ctl configtest
	systemctl restart apache2

	# Downloading WordPress
	echo "============================ Downloading WordPress ============================"
	apt install curl
	curl -O https://wordpress.org/latest.tar.gz
	tar xzvf latest.tar.gz
	touch ./wordpress/.htaccess

	cp ./wordpress/wp-config-sample.php ./wordpress/wp-config.php
	mkdir ./wordpress/wp-content/upgrade
	cp -a ./wordpress/. /var/www/wordpress

	# Configuring the WordPress Directory
	echo "============================ Configuring the WordPress Directory ============================"
	chown -R root:root /var/www/wordpress
	chmod -R 777 /var/www/wordpress

	sed -i "s/AUTH_KEY.*/AUTH_KEY',         'c_j{iwqD^<+c9.WEFk<J@4H');/" /var/www/wordpress/wp-config.php
	sed -i "s/SECURE_AUTH_KEY.*/SECURE_AUTH_KEY',         'c_j{iwqD^ASDF<+c9.k<J@4H');/" /var/www/wordpress/wp-config.php
	sed -i "s/LOGGED_IN_KEY.*/LOGGED_IN_KEY',         'c_j{iwqD^<ASDVCD+c9.k<J@4H');/" /var/www/wordpress/wp-config.php
	sed -i "s/NONCE_KEY.*/NONCE_KEY',         'c_j{iwqD^<+cASDFA9.k<J@4H');/" /var/www/wordpress/wp-config.php
	sed -i "s/AUTH_SALT.*/AUTH_SALT',         'c_j{iwqD^<+VSDASDFc9.k<J@4H');/" /var/www/wordpress/wp-config.php
	sed -i "s/SECURE_AUTH_SALT.*/SECURE_AUTH_SALT',         'c_j{iASDCASDwqD^<+c9.k<J@4H');/" /var/www/wordpress/wp-config.php
	sed -i "s/LOGGEN_IN_SALT.*/LOGGEN_IN_SALT',         'c_j{iwqASDFWED^<+c9.k<J@4H');/" /var/www/wordpress/wp-config.php
	sed -i "s/NONCE_SALT.*/NONCE_SALT',         'c_j{iwqD^<+c9.ZXCVASDFAGk<J@4H');/" /var/www/wordpress/wp-config.php

	sed -i "s/DB_NAME.*/DB_NAME', '${DB_NAME}');/" /var/www/wordpress/wp-config.php
	sed -i "s/DB_USER.*/DB_USER', '${DB_USER}');/" /var/www/wordpress/wp-config.php
	sed -i "s/DB_PASSWORD.*/DB_PASSWORD', '${DB_PASS}');/" /var/www/wordpress/wp-config.php
	if grep -q "FS_METHOD" "/var/www/wordpress/wp-config.php"; then
		sed -i "s/FS_METHOD.*/FS_METHOD', 'direct');/" /var/www/wordpress/wp-config.php
    else
    	echo "define('FS_METHOD', 'direct');" >> /var/www/wordpress/wp-config.php
	fi

	chown -R www-data:www-data /var/www/wordpress
	find /var/www/wordpress/ -type d -exec chmod 750 {} \;
	find /var/www/wordpress/ -type f -exec chmod 640 {} \;
else
	echo "###########################################"
	echo "Unknown Task"
	echo "###########################################"
fi
