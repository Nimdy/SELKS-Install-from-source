=====
SELKS ver5
=====

Intro
=====

SELKS is a free and open source Debian (with LXDE X-window manager) based IDS/IPS platform 
released under GPLv3 from Stamus Networks (https://www.stamus-networks.com/).

Their GITHUB is: https://github.com/StamusNetworks


=============
This is a SOP to install SELKS from source and not from ISO, if you wish to use ISO:

You can download ready to use images from the `SELKS download page <https://www.stamus-networks.com/open-source/#selks>`_.
    
How to run SELKS
===============

Prerequisites
-------------
Debian 9.5+ Stretch
2CPU / 8+ GB RAM (More RAM the better 16+)
Two NIC cards: One for management access and the other one for monitoring


How to install
==============

Update debian

sudo apt-get update

sudo apt-get install git

cd /opt/

git clone https://github.com/Nimdy/SELKS-Install-from-source.git

cd /SELKS/-Install-from-source

sudo chmod -x install_SELKS.sh

After Install
=============

Reboot and login to the system

cd /SELKS


ADDAING MORE

