==================================================================================
=SELKS Ver5 Build from Source for AWS and AZURE Cloud Network Security Monitoring=
==================================================================================

Intro
=====

SELKS is a free and open source Debian (with LXDE X-window manager) based IDS/IPS platform 
released under GPLv3 from Stamus Networks (https://www.stamus-networks.com/).

Their GITHUB is: https://github.com/StamusNetworks

Their SELKS WIKI: https://github.com/StamusNetworks/SELKS


================================================================================================================================
=This is a how-to about installing SELKS from source and not from ISO, if you wish to use ISO:                                 =      
=                                                                                                                              =
=You can download ready to use images from the `SELKS download page <https://www.stamus-networks.com/open-source/#selks>`_.    =
=                                                                                                                              =                 
================================================================================================================================


Prerequisites
=============
Debian 9.5+ Stretch
2CPU / 8+ GB RAM (More RAM the better 16+)
Two NIC cards: One for management access and the other one for monitoring
Coffee.... lots of coffee 

How to install
==============


Update and upgrade debian
=========================

apt-get update
apt-get upgrade

Install GIT
========================
sudo apt-get install -y git

Change directory to OPT
=======================
cd /opt/

Pull GIT from Nimdy
===================

git clone https://github.com/Nimdy/SELKS-Install-from-source.git

Change directory
================

cd /SELKS-Install-from-source

Change permissions to execute script
====================================

sudo chmod -x install_SELKS.sh

Select "Yes" for Scirius database configuration

After Install
=============

Reboot and login to the system

Change root password, if required. Default password is StamusNetworks.

cd /opt/selks/Scripts/Setup


Setup interface and mon Full Packet Capture settings
====================================================
./selks-first-time-setup.sh
        
        ======================================================
        =Select interface you wish to receive network traffic=
        ======================================================
        ie: eth1
        ===================
        =Set PCAP Settings=
        ===================
        ie: option 1
        


Verfiy services are running
===========================

systemctl status kibana logstash elasticsearch suricata

        ======================================================================================================================
        =If there are any errors with kibana or any other service restart the service and review the logs, if issues continue=
        ======================================================================================================================
        service kibana restart
        service kibana status
        
================================
=Configure HOMENET for Suricata=
================================

vi /etc/suricata/suricata.yaml

        Edit to reflect network range monitored:   HOME_NET: '[192.168.0.0/16,10.0.0.0/8,172.16.0.0./12]"
       =============================================
       =Restart suricata service to reflect changes=
       =============================================
        service suricata restart
        
===================================================================================        
=Visit SELKS Scirius Dashboards to verify dashboards are setup and populating data=
===================================================================================

https://ipofSELKSinstall

Click Dashboards

Click logstash-* 

        Set as default index by clicking the star icon
        
Click Dashboards 

        Click SN-ALL
        

Test Suricata is working
=========================

curl testmyids.com

Visit Scirius dashboard and review alert.
 
=======================================
=Validate interface is in promisc mode=
=======================================

ifconfig

if interface does not say promisc, then set it manually.

=====================================
= Configure /etc/network/interfaces =
=====================================
vi /etc/network/interface

        ================================
        = Replace or add the following =
        ================================
        auto eth1
            iface eth1 inet manual
            up ifconfig eth1 promisc up
            down ifconfig eth1 promisc down
            
===================
= safe file in vi =
===================
:wq!


======================
= restart networking =
======================

systemctl restart networking






NOT COMPLETE ADDING MORE 

Need to format to Markup....

