#!/usr/bin/env bash

SAMPLE_DATA=$1
HOST=$2
DATA_VERSION="1.9.2.4"

# Update Apt
# --------------------
# apt-get update

# Install htop and mc
# --------------------
apt-get install -y htop
apt-get install -y mc

# Mysql
# --------------------
# Ignore the post install questions
export DEBIAN_FRONTEND=noninteractive
# Install MySQL quietly
apt-get -q -y install mysql-server-5.6

mysql -u root -e "CREATE DATABASE IF NOT EXISTS magento1"
mysql -u root -e "GRANT ALL PRIVILEGES ON magento1.* TO 'magento'@'localhost' IDENTIFIED BY 'magento'"
mysql -u root -e "FLUSH PRIVILEGES"

# Install Apache & PHP
# --------------------
apt-get install -y apache2
apt-get install -y php5
apt-get install -y libapache2-mod-php5
apt-get install -y php5-mysqlnd php5-curl php5-xdebug php5-gd php5-intl php-pear php5-imap php5-mcrypt php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-soap

php5enmod mcrypt

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf /var/www/html
ln -fs /vagrant/code /var/www/html

# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
NameVirtualHost *:80
Listen 8080
<VirtualHost *:80>
  DocumentRoot "/var/www/html"
  ServerName $HOST
  <Directory "/var/www/html">
    AllowOverride All
  </Directory>
</VirtualHost>
<VirtualHost *:8080>
  DocumentRoot "/var/www/html"
  ServerName $HOST
  <Directory "/var/www/html">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

a2enmod rewrite

echo "ServerName $HOST" | tee /etc/apache2/conf-available/fqdn.conf
a2enconf fqdn

echo "AddDefaultCharset UTF-8" | tee /etc/apache2/conf-available/charset.conf

service apache2 restart


# Sample Data
if [[ $SAMPLE_DATA == "true" ]]; then
  cd /vagrant

  if [[ ! -f "/vagrant/magento-sample-data-${DATA_VERSION}.tar.gz" ]]; then
    # Only download sample data if we need to
    wget http://www.magentocommerce.com/downloads/assets/${DATA_VERSION}/magento-sample-data-${DATA_VERSION}.tar.gz
  fi

  tar -zxvf magento-sample-data-${DATA_VERSION}.tar.gz
  cp -R magento-sample-data-${DATA_VERSION}/media/* httpdocs/media/
  cp -R magento-sample-data-${DATA_VERSION}/skin/*  httpdocs/skin/
  mysql -u root magentodb < magento-sample-data-${DATA_VERSION}/magento_sample_data_for_${DATA_VERSION}.sql
  rm -rf magento-sample-data-${DATA_VERSION}
fi


# Run installer
if [ ! -f "/vagrant/code/app/etc/local.xml" ]; then
  cd /vagrant/code
  /usr/bin/php -f install.php -- \
  --license_agreement_accepted "yes" \
  --locale "en_US" \
  --timezone "Europe/Moscow" \
  --default_currency "USD" \
  --db_host localhost \
  --db_name magento1 \
  --db_user magento \
  --db_pass magento \
  --url "http://$HOST/" \
  --use_rewrites "yes" \
  --use_secure "no" \
  --secure_base_url "https://$HOST/" \
  --use_secure_admin "no" \
  --skip_url_validation "yes" \
  --admin_frontname "manager" \
  --admin_lastname "Admin" \
  --admin_firstname "Admin" \
  --admin_email "admin@example.com" \
  --admin_username "admin" \
  --admin_password "a123456" \
  --session_save "db"
  /usr/bin/php -f shell/indexer.php reindexall
fi

# Install n98-magerun
# --------------------
cd /vagrant/provision/n98-magerun
sudo cp ./n98-magerun.phar /usr/local/bin/n98-magerun
sudo chmod +x /usr/local/bin/n98-magerun
