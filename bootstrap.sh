#!/usr/bin/env bash

################################################################################
#
# CONFIG
#
################################################################################

MYSQL_PASSWORD=secret
ECHO_PREFIX="[BOOTSTRAP]"

################################################################################
#
# COMMON
#
################################################################################

echo "${ECHO_PREFIX} Creating sources.list with german mirrors ..."
cat > /etc/apt/sources.list <<EOF
# untested:
#deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe multiverse
#deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates main restricted universe multiverse
#deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-backports main restricted universe multiverse
#deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted universe multiverse

deb http://de.archive.ubuntu.com/ubuntu trusty main restricted universe multiverse
deb-src http://de.archive.ubuntu.com/ubuntu trusty main restricted universe multiverse

deb http://de.archive.ubuntu.com/ubuntu trusty-updates main restricted universe multiverse
deb-src http://de.archive.ubuntu.com/ubuntu trusty-updates main restricted universe multiverse

deb http://de.archive.ubuntu.com/ubuntu trusty-security main restricted universe multiverse
deb-src http://de.archive.ubuntu.com/ubuntu trusty-security main restricted universe multiverse

deb http://de.archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse
deb-src http://de.archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse

deb http://extras.ubuntu.com/ubuntu trusty main
EOF

echo "${ECHO_PREFIX} Updating package cache ..."
apt-get -y update

echo "${ECHO_PREFIX} Installing basic packages ..."
apt-get -y install build-essential curl git zip unzip

################################################################################
#
# APACHE
#
################################################################################

echo "${ECHO_PREFIX} Installing Apache ..."
apt-get -y install apache2

# delete default webserver page
# and replace it with a symlink
# to the default vagrant shared folder
if ! [ -L /var/www ]; then
    echo "${ECHO_PREFIX} Creating webroot ..."
    rm -rf /var/www
    ln -fs /vagrant /var/www

    a2enmod rewrite

    sed -i '/AllowOverride None/c AllowOverride All' /etc/apache2/sites-available/default

    service apache2 restart
fi

################################################################################
#
# PHP
#
################################################################################

echo "${ECHO_PREFIX} Installing PHP ..."
apt-get -y install php5 php-pear

################################################################################
#
# MySQL
#
################################################################################

echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_PASSWORD" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASSWORD" | debconf-set-selections

echo "${ECHO_PREFIX} Installing MySQL ..."
apt-get -y install mysql-server php5-mysql

# Create databases
if [ ! -f /var/log/databasesetup ];
then
    echo "CREATE USER 'wordpressuser'@'localhost' IDENTIFIED BY 'wordpresspass'" | mysql -uroot -p$MYSQL_PASSWORD
    echo "CREATE DATABASE wordpress" | mysql -uroot -p$MYSQL_PASSWORD
    echo "GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost'" | mysql -uroot -p$MYSQL_PASSWORD
    echo "flush privileges" | mysql -uroot -p$MYSQL_PASSWORD

    touch /var/log/databasesetup

    if [ -f /vagrant/data/initial.sql ];
    then
        mysql -uroot -p$MYSQL_PASSWORD wordpress < /vagrant/data/initial.sql
    fi
fi

################################################################################
#
# PHPMyAdmin
#
################################################################################

echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/password-confirm password $MYSQL_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/setup-password password $MYSQL_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/database-type select mysql" | debconf-set-selections

echo "${ECHO_PREFIX} Installing PHPMyAdmin ..."
apt-get -y install phpmyadmin

################################################################################
#
# Finalize
#
################################################################################

echo "${ECHO_PREFIX} Provisioning done."
