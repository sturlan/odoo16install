!/bin/bash
#General instructions:
#https://www.odoo.com/documentation/16.0/administration/install.html
#0 install stuff
#1 create user for odoo - does not have to be sudo, can be disabled to login, system user with no password but it MUST have a home folder
#2 create postgres user odoo, doesn't have to be super user, needs createdb privileges, no need to create a database at this point
#3 setup odoo to run as a service, autostart on system startup and setup logging
#4 install wkhtmltopdf

#0
apt update -y && apt upgrade -y
apt install -y sudo nano git wget openssh-server fail2ban postgresql postgresql-client python3 python3-pip
cd /opt/
git clone --single-branch --depth 1 -b 16.0 https://github.com/odoo/odoo.git
cd /opt/odoo
sed -n -e '/^Depends:/,/^Pre/ s/ python3-\(.*\),/python3-\1/p' debian/control | sudo xargs apt-get install -y
#1
useradd -s /bin/bash -mr odoo
chown odoo -R /opt/odoo
#2
sudo -u postgres createuser --createdb --username postgres --no-createrole --no-superuser odoo
#check if odoo is working
#sudo -u odoo /opt/odoo/odoo-bin --addons-path /opt/odoo/addons/
#3
#create log folder
mkdir /var/log/odoo
chown odoo -R /var/log/odoo

#create config file
printf '%s[options%s]%s\ndb_host = False%s\ndb_port = False%s\ndb_user = odoo%s\ndb_password = False%s\naddons_path = /opt/odoo/addons%s\nlogfile = /var/log/odoo/odoo.log%s\n' > /etc/odoo.conf
chmod 640 /etc/odoo.conf
chown odoo /etc/odoo.conf

#create service file
printf '%s[Unit%s]%s\nDescription=Odoo%s\nDocumentation=http://www.odoo.com%s\n%s[Service%s]%s\nType=simple%s\nUser=odoo%s\nExecStart=/opt/odoo/odoo-bin -c /etc/odoo.conf%s\n%s[Install%s]%s\nWantedBy=default.target' > /etc/systemd/system/odoo.service
chmod 755 /etc/systemd/system/odoo.service
chown root /etc/systemd/system/odoo.service

#reload services, autostart enable and start
systemctl daemon-reload
systemctl enable odoo

#4
cd /tmp
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb
dpkg -i wkhtmltox_0.12.6-1.buster_amd64.deb
apt install -y --fix-broken && apt install -y -f

systemctl start odoo
