apt update
apt install curl wget unzip -y

apt install apache2 -y
systemctl enable apache2
systemctl start apache2

curl http://127.0.0.1
chown :adm /var/log/apache2/*

apt install php php-mysql libapache2-mod-php php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y
apt install mariadb-server mariadb-client -y
systemctl enable mariadb
systemctl start mariadb

mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY '&Cintra-1949';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '&Cintra-1949';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host!='localhost';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

cd /tmp
wget https://wordpress.org/latest.zip
unzip latest.zip
mv wordpress /var/www/html/
chown -R www-data:www-data /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

cd /var/www/html/wordpress
cp wp-config-sample.php wp-config.php

sed -i 's/database_name_here/wordpress/g' /var/www/html/wordpress/wp-config.php
sed -i 's/username_here/wpuser/g' /var/www/html/wordpress/wp-config.php
sed -i 's/password_here/\&Cintra-1949/g' /var/www/html/wordpress/wp-config.php

sed -i "87a define('WP_HOME','http://localhost:8080');\ndefine('WP_SITEURL','http://localhost:8080');" /var/www/html/wordpress/wp-config.php
sed -i "s/DEBUG', false/DEBUG', true/g" /var/www/html/wordpress/wp-config.php
sed -i "89a\define('WP_DEBUG_LOG', true);" /var/www/html/wordpress/wp-config.php
sed -i "90a\define('WP_DEBUG_DISPLAY', false);" /var/www/html/wordpress/wp-config.php
sed -i 's/\r$//' /var/www/html/wordpress/wp-config.php

cat <<EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/html/wordpress
    ErrorLog /var/log/apache2/wordpress_error.log
    CustomLog /var/log/apache2/wordpress_access.log combined

    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
rm /etc/apache2/sites-enabled/000-default.conf
a2ensite wordpress.conf
a2enmod rewrite
systemctl restart apache2

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.19.12-amd64.deb
dpkg -i filebeat-8.19.12-amd64.deb

useradd --system --no-create-home --shell /usr/sbin/nologin filebeat
mkdir -p /var/lib/filebeat/registry
mkdir -p /var/log/filebeat
chown -R filebeat:filebeat /var/lib/filebeat /var/log/filebeat
chmod -R 750 /var/lib/filebeat /var/log/filebeat

sed -i '13a\User=filebeat' /usr/lib/systemd/system/filebeat.service
sed -i '14a\Group=filebeat' /usr/lib/systemd/system/filebeat.service

systemctl daemon-reload

sed -i 's/type: filestream/type: log/g' /etc/filebeat/filebeat.yml
sed -i 's/enabled: false/enabled: true/g' /etc/filebeat/filebeat.yml
sed -i 's/output.elasticsearch/#output.elasticsearch/g' /etc/filebeat/filebeat.yml
sed -i 's/hosts: \["localhost:9200"\]/#hosts: \["localhost:9200"\]/g' /etc/filebeat/filebeat.yml 
sed -i 's/#output.logstash/output.logstash/g' /etc/filebeat/filebeat.yml
sed -i 's/#hosts: \["localhost:5044"\]/hosts: \["192.168.128.11:5044"\]/g' /etc/filebeat/filebeat.yml
sed -i '183a\  ssl.enabled: true' /etc/filebeat/filebeat.yml 
sed -i '184a\  ssl.certificate_authorities: ["/etc/filebeat/certs/ca.crt"]' /etc/filebeat/filebeat.yml
sed -i '185a\  ssl.certificate: "/etc/filebeat/certs/filebeat.crt"' /etc/filebeat/filebeat.yml
sed -i '186a\  ssl.key: "/etc/filebeat/certs/filebeat.key"' /etc/filebeat/filebeat.yml
sed -i 's/\/var\/log\//\/var\/log\/apache2\//g' /etc/filebeat/filebeat.yml

mkdir -p /etc/filebeat/certs
cp /vagrant/ca.crt /etc/filebeat/certs
cp /vagrant//filebeat.* /etc/filebeat/certs
chown filebeat: /etc/filebeat/certs/*
chmod 600 /etc/filebeat/certs/*

chown -R filebeat:filebeat /var/lib/filebeat /var/log/filebeat
chmod -R 750 /var/lib/filebeat /var/log/filebeat
chown root:filebeat /etc/filebeat/filebeat.yml
chmod 640 /etc/filebeat/filebeat.yml

usermod -aG adm filebeat
usermod -aG syslog filebeat

systemctl enable filebeat
systemctl start filebeat

filebeat modules enable apache

cat <<EOF > /etc/filebeat/modules.d/apache.yml
- module: apache
  access:
    enabled: true
    var.paths: ["/var/log/apache2/access.log*"]

  error:
    enabled: true
    var.paths: ["/var/log/apache2/error.log*"]
EOF

systemctl restart filebeat
