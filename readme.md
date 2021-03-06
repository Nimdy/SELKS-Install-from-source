# SELKS Ver5 Build from Source for AWS and AZURE Cloud Network Security Monitoring 

SELKS is a free and open source Debian (with LXDE X-window manager) based IDS/IPS platform 
released under GPLv3 from Stamus Networks (https://www.stamus-networks.com).

Their GITHUB is: https://github.com/StamusNetworks

Their SELKS WIKI: https://github.com/StamusNetworks/SELKS






#### This is a how-to about installing SELKS from source and not from ISO, if you wish to use ISO:                          
You can download ready to use images from the SELKS download page https://www.stamus-networks.com/open-source/selks  


 Prerequisites 
=

- Debian 9.5+ Stretch
- 2CPU / 8+ GB RAM (More RAM the better 16+)
- Two NIC cards: One for management access and the other one for monitoring
- Coffee.... lots of coffee 


 Add current user is in sudo group if not running dangerously in root ^_-
=

-  usermod -aG sudo username


Install time!!!
=


Update and upgrade debian
=
```sh
sudo apt update
sudo apt upgrade
```
Install GIT 
=
```sh
sudo apt-get install -y git net-tools
```

Change directory to OPT
=
```sh
cd /opt/
```

Clone GIT from Nimdy
=
```sh
sudo git clone https://github.com/Nimdy/SELKS-Install-from-source.git
```


 Clone GIT from SELKS for staging files required system config  
 =
 ##### The install script copies the SELKS staging files for later use. After the install is complete, do a system reboot.

```sh 
sudo git clone https://github.com/StamusNetworks/SELKS.git SELKS_CONFIGS

```

Change directory
=
```sh
cd SELKS-Install-from-source
```

Change permissions to execute script
=
```sh
sudo chmod +x install_SELKS.sh
```
Execute script
=
```sh
sudo ./install_SELKS.sh
```

During install you might be asked a question about Scirius database related information:
=
```
        Select "Yes" for Scirius database configuration
```

After Succesfull Installation 
=

- Reboot and login to the system

- Change root password, if required. Default password is StamusNetworks.
```sh
cd /usr/bin
```

Setup interface and mon Full Packet Capture settings
=
```sh
./selks-first-time-setup
```        

Select interface you wish to receive network traffic
=

> Select interface - ie: eth1

> Select PCAP setting -  ie: option 1 


# Check for SELKS upgrades

```sh
cd /usr/bin
./selks-upgrade_stamus
```

# Verfiy services are running
=

```sh
systemctl status kibana logstash elasticsearch suricata
```

### If there are any errors with kibana or any other service restart the service and review the logs, if issues continue
=
```sh
        systemctl restart kibana 
        systemctl status kibana 
```        

Configure HOMENET for Suricata 
=
```sh
        vi /etc/suricata/suricata.yaml
```
> Edit to reflect network range monitored:   HOME_NET: '[192.168.0.0/16,10.0.0.0/8,172.16.0.0./12]"
 
 Restart suricata service to reflect changes
=
```sh
        systemctl restart suricata
```
      
#### Visit SELKS Scirius Dashboards to verify dashboards are setup and populating data


- https://ipofSELKSinstall

- Click Dashboards

- Click logstash-* 

- Set as default index by clicking the star icon
       
- Click Dashboards 

- Click SN-ALL
        

Test Suricata is working
=
```sh
        curl testmyids.com
```
- Visit Scirius dashboard and review alert.
 

Validate interface is in promisc mode
=
```sh
        ifconfig
```
> if interface does not say promisc, then set it manually.

Configure /etc/network/interfaces
=
```sh
        vi /etc/network/interface
```

> Replace or add the following 

        auto eth1
            iface eth1 inet manual
            up ifconfig eth1 0.0.0.0 up
            up link set eth1 promisc on
            down ip link set eth1 promisc off
            down ifconfig eth1 down
> Save File          
```sh
    :wq!
```


Restart networking
=
```sh
        systemctl restart networking
```

## Upgrade Kernel for CIFS SMB3 because Debian 9 with Linux Kernel 4.9 does not support SMB3 connections. This upgrade will push you over the 4.11 requirement and upgrade you to 4.19.
```sh
apt -t stretch-backports upgrade
```
Say yes to all

Reboot

## Security in mind - Check STIGs                
#### SCAP Security Guide implements security guidances recommended by respected authorities, namely PCI DSS, STIG, and USGCB. SCAP Security Guide transforms these security guidances into a machine readable format which then can be used by OpenSCAP to audit your system. 

```sh
https://www.open-scap.org/security-policies/scap-security-guide/
```


SELKS Master WIKI - This has a ton of great information!
=

> Visit: https://github.com/StamusNetworks/SELKS/wiki for more tips.

> Visit: https://github.com/StamusNetworks/SELKS/wiki/Tuning-SELKS for fine tuning SELKS



#### Need help just ask. :)


# SPECIAL Thanks to the SELKS team for helping me during my Azure nightmare and enabling me to build this how-to for others on the interwebz.




