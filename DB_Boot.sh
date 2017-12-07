

echo Installing Packages...
sudo yum localinstall -y https://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
sudo yum install -y git python-argparse epel-release mysql-connector-java* mysql-community-server


# MySQL Setup to keep the new services separate from the originals
echo Database setup...
sudo systemctl enable mysqld.service
sudo systemctl start mysqld.service

#extract system generated Mysql password
oldpass=$( grep 'temporary.*root@localhost' /var/log/mysqld.log | tail -n 1 | sed 's/.*root@localhost: //' )


#create sql file that
# 1. reset Mysql password to temp value and create druid/superset/registry/streamline schemas and users
# 2. sets passwords for druid/superset/registry/streamline users to StrongPassword
cat << EOF > mysql-setup.sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Secur1ty!'; 
uninstall plugin validate_password;

CREATE DATABASE druid DEFAULT CHARACTER SET utf8; 
CREATE DATABASE superset DEFAULT CHARACTER SET utf8; 
CREATE DATABASE registry ; 
CREATE DATABASE streamline DEFAULT CHARACTER SET utf8; 
CREATE DATABASE ranger;

CREATE USER 'druid'@'%' IDENTIFIED BY 'StrongPassword'; 
CREATE USER 'superset'@'%' IDENTIFIED BY 'StrongPassword'; 
CREATE USER 'registry'@'%' IDENTIFIED BY 'StrongPassword'; 
CREATE USER 'streamline'@'%' IDENTIFIED BY 'StrongPassword';
CREATE USER 'rangeradmin'@'%' IDENTIFIED BY 'StrongPassword'; 

GRANT ALL PRIVILEGES ON *.* TO 'druid'@'%' WITH GRANT OPTION; 
GRANT ALL PRIVILEGES ON *.* TO 'superset'@'%' WITH GRANT OPTION; 
GRANT ALL PRIVILEGES ON registry.* TO 'registry'@'%' WITH GRANT OPTION ; 
GRANT ALL PRIVILEGES ON streamline.* TO 'streamline'@'%' WITH GRANT OPTION ; 
GRANT ALL PRIVILEGES ON ranger.* TO 'rangeradmin'@'%' WITH GRANT OPTION ; 
commit; 
EOF

#execute sql file
mysql -h localhost -u root -p"$oldpass" --connect-expired-password < mysql-setup.sql
#change Mysql password to StrongPassword
mysqladmin -u root -p'Secur1ty!' password StrongPassword
#test password and confirm dbs created
mysql -u root -pStrongPassword -e 'show databases;'