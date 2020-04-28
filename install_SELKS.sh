#!/bin/bash

# Copyright Stamus Networks, 2018
# All rights reserved
# Debian Live/Install ISO script - oss@stamus-networks.com
# Modified by Nimdy for AWS, AZURE, Home labs, and anything else I suppose
# Please run on Debian Stretch
#Updated.... for 2020

##ADD required deps

apt-get update && \

apt-get install -y libpcre3 libpcre3-dbg libpcre3-dev ntp build-essential autoconf automake libtool libpcap-dev libnet1-dev \
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 make flex bison git git-core libmagic-dev \
libnuma-dev pkg-config libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0  libjansson-dev \
libjansson4 libnss3-dev libnspr4-dev libgeoip1 libgeoip-dev rsync mc python-daemon libnss3-tools curl net-tools \
python-crypto libgmp10 libyaml-0-2 python-simplejson python-pygments python-yaml ssh sudo tcpdump nginx openssl jq patch \
python-pip debian-installer-launcher live-build apt-transport-https ethtool



# Copyright Stamus Networks, 2019
# All rights reserved
# Debian Live/Install ISO script - oss@stamus-networks.com
#
# Please run on Debian Stretch

set -ex

# Setting up the LIVE root (during install on disk it is preseeded)
echo "root:StamusNetworks" | chpasswd

# Enable color output and the "ll" command in shell 
echo " export LS_OPTIONS='--color=auto'" >> /root/.bashrc
echo " alias ll='ls $LS_OPTIONS -l'" >> /root/.bashrc

###  Set up repos ###

wget -qO - http://packages.stamus-networks.com/packages.selks5.stamus-networks.com.gpg.key | apt-key add - 
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
wget -qO - https://evebox.org/files/GPG-KEY-evebox | apt-key add -

cat >> /etc/apt/sources.list.d/elastic-6.x.list <<EOF
deb https://artifacts.elastic.co/packages/6.x/apt stable main
EOF

cat >> /etc/apt/sources.list.d/curator5.list <<EOF
deb [arch=amd64] https://packages.elastic.co/curator/5/debian9 stable main
EOF

cat >> /etc/apt/sources.list.d/evebox.list <<EOF
deb http://files.evebox.org/evebox/debian stable main
EOF

cat >> /etc/apt/sources.list.d/selks5.list <<EOF
# SELKS 5 Stamus Networks repos
#
# Manual changes here can be overwritten during 
# SELKS updates and upgrades !!

deb http://packages.stamus-networks.com/selks5/debian/ stretch main
deb http://packages.stamus-networks.com/selks5/debian-kernel/ stretch main
#deb http://packages.stamus-networks.com/selks5/debian-test/ stretch main
EOF

###  END Set up repos ###

mkdir -p  /opt/selks/

### START JAVA for ELK ###

apt-get update && \
apt-get install -y ca-certificates-java openjdk-8-jre-headless \
openjdk-8-jdk openjdk-8-jre openjdk-8-jre-headless

### END JAVA for ELK ###

### START ELK ###

apt-get update && \
apt-get install -y elasticsearch logstash kibana elasticsearch-curator

mkdir -p /var/cache/logstash/sincedbs/
chown logstash:logstash /var/cache/logstash/sincedbs/
/usr/share/logstash/bin/logstash-plugin install logstash-filter-geoip

/bin/systemctl enable elasticsearch && \
/bin/systemctl enable logstash && \
/bin/systemctl enable kibana && \
/bin/systemctl daemon-reload

### END ELK ###

### START Suricata ###

apt-get update && \
apt-get install -y -o Dpkg::Options::="--force-confdef" suricata 
#make sure Suricata can write in /data/nsm
chown logstash -R /data/nsm/

### END Suricata ###


### START Install kibana dashboards ###

apt-get install -y kibana-dashboards-stamus

### END Install kibana dashboards ###

### START Evebox ###

apt-get update && \
apt-get install -y evebox
/bin/systemctl enable evebox

### END Evebox ###

### START Scirius, nginx, revrse proxy, supervisor and ssl ###

mkdir -p /var/lib/scirius/static/
apt-get update && \
apt-get install -y scirius
sed -i 's/ELASTICSEARCH_VERSION = 5/ELASTICSEARCH_VERSION = 6/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA_VERSION=4/KIBANA_VERSION = 6/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA_INDEX = "kibana-int"/KIBANA_INDEX = ".kibana"/g' /etc/scirius/local_settings.py
sed -i 's/KIBANA_DASHBOARDS_PATH = "\/opt\/selks\/kibana5-dashboards\/"/KIBANA6_DASHBOARDS_PATH = "\/opt\/selks\/kibana6-dashboards\/"/g' /etc/scirius/local_settings.py
echo "ELASTICSEARCH_KEYWORD = \"keyword\"" >> /etc/scirius/local_settings.py


# supervisor conf
ln -s /usr/share/doc/scirius/examples/scirius-supervisor.conf /etc/supervisor/conf.d/scirius-supervisor.conf

# Set the right permissions for the logstash user to run suricata
chown -R logstash:logstash /var/log/suricata

# www-data needs to write Suricata rules
chown -R www-data.www-data /etc/suricata/rules/

mkdir -p /etc/nginx/ssl
openssl req -new -nodes -x509 -subj "/C=FR/ST=IDF/L=Paris/O=Stamus/CN=SELKS" -days 3650 -keyout /etc/nginx/ssl/scirius.key -out /etc/nginx/ssl/scirius.crt -extensions v3_ca 

rm -rf /etc/nginx/sites-enabled/default

cat >> /etc/nginx/sites-available/selks5.conf <<EOF
server {
    listen 127.0.0.1:80;
    listen 127.0.1.1:80;
    listen 443 default_server ssl;
    ssl_certificate /etc/nginx/ssl/scirius.crt;
    ssl_certificate_key /etc/nginx/ssl/scirius.key;
    server_name SELKS;
    access_log /var/log/nginx/scirius.access.log;
    error_log /var/log/nginx/scirius.error.log;

    # https://docs.djangoproject.com/en/dev/howto/static-files/#serving-static-files-in-production
    location /static/ { # STATIC_URL
        alias /var/lib/scirius/static/; # STATIC_ROOT
        expires 30d;
    }

    location /media/ { # MEDIA_URL
        alias /var/lib/scirius/static/; # MEDIA_ROOT
        expires 30d;
    }

    location /app/moloch/ {
        proxy_pass https://127.0.0.1:8005;
        proxy_redirect off;
    }

    location /plugins/ {
        proxy_pass http://127.0.0.1:5601/plugins/;
        proxy_redirect off;
    }

    location /dlls/ {
        proxy_pass http://127.0.0.1:5601/dlls/;
        proxy_redirect off;
    }

    location /socket.io/ {
        proxy_pass http://127.0.0.1:5601/socket.io/;
        proxy_redirect off;
    }

    location /dataset/ {
        proxy_pass http://127.0.0.1:5601/dataset/;
        proxy_redirect off;
    }

    location /translations/ {
        proxy_pass http://127.0.0.1:5601/translations/;
        proxy_redirect off;
    }

    location ^~ /built_assets/ {
        proxy_pass http://127.0.0.1:5601/built_assets/;
        proxy_redirect off;
    }

    location /ui/ {
        proxy_pass http://127.0.0.1:5601/ui/;
        proxy_redirect off;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_read_timeout 600;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect off;
    }

}
EOF

# enable sites
ln -s /etc/nginx/sites-available/selks5.conf /etc/nginx/sites-enabled/selks5.conf

cd /usr/share/python/scirius/ && \
source bin/activate
python bin/manage.py loaddata /etc/scirius/scirius.json
python bin/manage.py addsource "ETOpen Ruleset" https://rules.emergingthreats.net/open/suricata-git/emerging.rules.tar.gz http sigs
#python bin/manage.py addsource "SSLBL abuse.ch" https://sslbl.abuse.ch/blacklist/sslblacklist.rules http sig
python bin/manage.py addsource "Suricata Traffic ID ruleset" https://raw.githubusercontent.com/jasonish/suricata-trafficid/master/rules/traffic-id.rules http sig
python bin/manage.py defaultruleset "Default SELKS ruleset"
python bin/manage.py addsuricata SELKS "Suricata on SELKS" /etc/suricata/rules "Default SELKS ruleset"
python bin/manage.py updatesuricata
deactivate

/usr/bin/supervisorctl reread && \
/usr/bin/supervisorctl update && \
/usr/bin/supervisorctl restart scirius && \
/bin/systemctl restart nginx
/bin/systemctl enable supervisor

# set permissions for Scirius 
touch /var/log/scirius.log
touch /var/log/scirius-error.log
chown www-data /var/log/scirius*
chown -R www-data /var/lib/scirius/git-sources/
chown -R www-data /var/lib/scirius/db/
chown -R www-data.www-data /etc/suricata/rules/

# fix permissions for user www-data/scirius
usermod -a -G logstash www-data
mkdir -p /var/run/suricata/
chmod g+w /var/run/suricata/ -R

### END Scirius, nginx, revrse proxy, supervisor and ssl ###

### START Moloch set up 

mkdir -p /opt/molochtmp
cd /opt/molochtmp/ && \
apt-get update && apt-get install -y libjson-perl libyaml-dev libcrypto++6 libwww-perl
wget https://files.molo.ch/builds/ubuntu-18.04/moloch_1.7.1-1_amd64.deb
dpkg -i moloch_1.7.1-1_amd64.deb

cd /opt/
rm /opt/molochtmp -r

# make sure we hold the moloch pkg version unless explicit upgrade is wanted/needed
apt-mark hold moloch

### END Moloch set up

### START Install SELKS/StamusN scripts ###

apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" selks-scripts-stamus

### END Install SELKS/StamusN scripts ###


# Set up a curator old logs removal
# flush everything that is older than 2 weeks

cat >> /opt/selks/delete-old-logs.sh <<EOF
#!/bin/bash

/opt/elasticsearch-curator/curator_cli delete_indices --filter_list \
'
[
  {
    "filtertype": "age",
    "source": "creation_date",
    "direction": "older",
    "unit": "days",
    "unit_count": 14
  },
  {
    "filtertype": "pattern",
    "kind": "prefix",
    "value": "logstash*"
  }
]
'
EOF

chmod 755 /opt/selks/delete-old-logs.sh

# Set up a cron jobs for Logstash, Scirius, rule updates
echo "0 2 * * * www-data ( cd /usr/share/python/scirius/ && . bin/activate && python bin/manage.py updatesuricata && deactivate )" >> /etc/crontab
echo "0 3 * * * root ( /data/moloch/db/db.pl http://127.0.0.1:9200 expire daily 14 )" >> /etc/crontab
echo "0 4 * * * root /opt/selks/delete-old-logs.sh" >> /etc/crontab
# always leave a empty line before cron files end
echo "" >> /etc/crontab

# Set up the host name
echo "SELKS" > /etc/hostname

# Enable the ssh banners
sed -i -e 's|\#Banner \/etc\/issue\.net|Banner \/etc\/issue\.net|'  /etc/ssh/sshd_config


# Edit the Icon "Install Debian Stretch" name on a Live Desktop 
# to "Install SELKS"
sed -i -e 's|Name\=Install Debian sid|Name\=Install SELKS|'  /usr/share/applications/debian-installer-launcher.desktop 

# Install exception for local certificate
certutil -A -n SELKS -t "P,p,p"  -i /etc/nginx/ssl/scirius.crt  -d /etc/iceweasel/profile/
chmod a+r /etc/iceweasel/profile/*db

apt-get update && \
apt-get install -y linux-headers-amd64

# Clean devel and some others packages
apt-get -y remove bison  autoconf automake libc6-dev autotools-dev libpcap-dev libnet1-dev libcap-ng-dev \
	libnetfilter-queue-dev  libnss3-dev libnspr4-dev \
	xscreensaver xscreensaver-data manpages-dev libjansson-dev \
	ghostscript xmms2-core x11proto-core-dev linux-libc-dev \
	rpm alien sane-utils libsane rpm2cpio \
	libx11-dev libx11-doc m4

apt-get autoremove -y
apt-get clean && \
cat /dev/null > ~/.bash_history && history -c


echo "System needs to reboot to make changes, please reboot and execute selks-first-time-install?"

