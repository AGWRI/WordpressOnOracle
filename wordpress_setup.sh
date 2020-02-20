#!/bin/bash
echo '------------------------------------'
echo '| Setting up Wordpress Version 5.2 |'
echo '------------------------------------'
echo '|   Implementing the following:    |'
echo '|        Apache Server 2.4+        |'
echo '|        MySQL Version 8.0+        |'
echo '|         PHP Version 7.2+         |'
echo '------------------------------------'
sleep 5
prerequisites=(https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm mysql80-community-release-el7-3.noarch.rpm oracle-php-release-el7)
packages=(httpd php php-mysql php-cli php-gd mysql-community-server)
wget ${prerequisites[0]}
sudo yum localinstall -y ${prerequisites[1]}
sudo yum install -y ${prerequisites[2]}
sudo yum install -y ${packages[@]}
wget -c https://wordpress.org/wordpress-5.2.5.tar.gz
tar -xzvf wordpress-5.2.5.tar.gz
sudo rsync -av wordpress/* /var/www/html/
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www/html/
sudo firewall-cmd --permanent --add-service http
sudo sed -i 's/# default-authentication-plugin=mysql_native_password/default-authentication-plugin=mysql_native_password/g' /etc/my.cnf
sudo service mysqld start
my_password=$(sudo grep 'temporary password' /var/log/mysqld.log)
echo 'Enter new root MySQL password:'
read -s root_new_passw
mysql -u root -p${my_password: -12} -e "ALTER USER root@localhost IDENTIFIED BY '$root_new_passw'"
echo -e "n\ny\ny\ny\ny\n" | sudo mysql_secure_installation -p${my_password: -12}
echo 'Enter the name for your Wordpress Database:'
read wp_db
echo 'Enter the name for the Database User:'
read wp_user
echo 'Enter the Databse User Password:'
read -s wp_passw
mysql -u root -p$root_new_passw -e "CREATE DATABASE $wp_db"
mysql -u root -p$root_new_passw -e "CREATE USER $wp_user@localhost IDENTIFIED BY '$wp_passw'"
mysql -u root -p$root_new_passw -e "GRANT ALL PRIVILEGES ON $wp_db.* TO $wp_user@localhost"
mysql -u root -p$root_new_passw -e "FLUSH PRIVILEGES"
sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '$wp_db' );/g" /var/www/html/wp-config.php
sudo sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '$wp_user' );/g" /var/www/html/wp-config.php
sudo sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '$wp_passw' );/g" /var/www/html/wp-config.php
#cleanup
unset prerequisites packages my_password root_new_passw wp_db wp_user wp_passw
sudo rm -r wordpress
sudo rm mysql80-community-release-el7-3.noarch.rpm
sudo rm wordpress-5.2.5.tar.gz
#end cleanup
sudo service httpd restart
sudo systemctl enable httpd
sudo service mysqld restart
sudo systemctl enable mysqld
echo 'Rebooting in 10 seconds...'
sleep 10
sudo reboot now
