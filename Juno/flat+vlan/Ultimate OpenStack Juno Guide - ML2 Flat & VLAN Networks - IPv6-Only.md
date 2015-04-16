# Ultimate OpenStack Juno Guide

This is a Quick Guide to deploy OpenStack Juno on top of Ubuntu 14.04.2, it is IPv6-Only (almost)! But, it can be used to deploy a IPv4-Only environment, just replace the IPs with `sed`.

It is compliant with OpenStack's official documentation (docs.openstack.org/juno).

The Project's (old "Tenant" terminology) subnets are based on Neutron, with ML2 plugin and `Single Flat Network` topology, Dual-Stacked, while of course, IPv4 is optional. The topology `VLAN Provider Networks` are also supported on this guide, it is very similar with `Single Flat Network`.

The `Single Flat Network` is the simplest network topology supported by OpenStack. So, it is easier to understand and follow. Then, you can start using `VLAN Provider Networks`, which is basically something like a "Multi-(Single Flat Network)", where each "Flat LAN" resides on its own VLAN tag.

Finally, the IPv6 support on `Neutron L3 Router` is ready! With ML2 plugin, you can have a Dual-Stacked environment on top of a `Single Flat Network / VLAN Provider Networks` without using `Neutron L3 Router` at all (i.e. by using upstream routers).

Apparently, only Metadata and the "GRE / VXLAN subnet" still requires IPv4. This is why this guide is "almost IPv6-Only". If you don't need Metadata Services, you don't need IPv4 either.

This is a "step-by-step", a "cut-and-paste" guide.

**This Guide covers:**

* Ubuntu (hostname, hosts, network interfaces, namespaces and LVM volumes);
* Open vSwitch;
* VLANs;
* RabbitMQ;
* MySQL;
* Keystone;
* Glance;
* Nova;
* SPICE Consoles - VDI (Virtual Desktop Infrastructure);
* Neutron with ML2 `Single Flat Network` & `VLAN Provider Networks`, Metadata and Security Groups;
* Cinder;
* and Dashboard.

**This Guide does not covers:**

* L3 Routers;
* NAT;
* Floating IPs;
* GRE or VXLAN tunnels.

## Donations Accepted... Bitcoins, Litecoins or Namecoins!

If you think that this guide is great! Please, consider a (micro)-Bitcoin (Litecoins or Namecoins are also welcome) donation to the following address:

* Bitcoin Address: `1JpNbLczAhUkbqQMv9iaQksiTd8yLaDx6K`

* Litecoin Address: `LTsHiv2LhTBYAYy9qjFrvohdtTEDSeym9M`

* Namecoin Address: `NHscBRrH7cCH4mboHt6zZnvyrAvTDn3UcM`

## Index

### 1. First things first, the upstream router
#### 1.1. Gateway (Ubuntu 14.04.2)
#### 1.2. Example of its /etc/network/interfaces file
#### 1.3. Enable IPv6 / IPv4 packet forwarding
#### 1.4. Upstream IPv6 Router Advertisement (SLAAC)
#### 1.5. NAT rule (Legacy)

### 2. Deploying the Controller Node
#### 2.1. Prepare Ubuntu O.S.
#### 2.2. Configure the network
#### 2.3. Install OpenStack "base" dependecies
#### 2.4. Install Keystone

### 3. Install Glance
#### 3.1. Configure Glance API
#### 3.2. Configure Glance Registry
#### 3.3. Adding O.S. images into your Glance
##### 3.3.1. CirrOS (Optional - TestVM)
##### 3.3.2. Ubuntu 13.10
##### 3.3.3. Ubuntu 12.04.5 - LTS
##### 3.3.4. Ubuntu 14.04.2 - LTS
##### 3.3.5. Ubuntu 14.10
##### 3.3.5. CoreOS
##### 3.3.6. Windows 2012 R2
#### 3.4. Listing the O.S. images

### 4. Install Nova
#### 4.1. Configure Nova
#### 4.2. Personalize your flavors (optional)

### 5. Install Neutron
#### 5.1. Configure Neutron
#### 5.2. Create the OpenStack Neutron Network
##### 5.2.1. Creating the Flat Provider Network
##### 5.2.1. Creating the VLAN Provider Network (optional)

### 7. Install Horizon Dashboard

### 6. Install Cinder (optional)
#### 6.1. Cinder API / endpoint access
#### 6.2. Cinder iSCSI block storage service

### 8. Deploying your first Compute Node
#### 8.1. Install Ubuntu 14.04.2
#### 8.2. Configure your Ubuntu KVM Hypervisor
#### 8.3. Configure the network
#### 8.4. Configure Nova
#### 8.5. Install Neutron

### 9. Creating your first Dual-Stacked Instance

### 10. TODO List

### 11. References

### 12. Limitations

### 13. Features

### 14. Observations
#### 14.1. About upstream router
#### 14.2. About IPv6
#### 14.3. About IPv4
#### 14.4. About NAT
#### 14.5. About configuration files

# *Outside of the Cloud Computing*

# 1. First things first, the upstream router

This lab have an Ubuntu acting as an "Upstream Router" with SLAAC enabled, it have two ethernet cards, with a "WAN / ISP / uplink" attached to its `eth0`, and "behind it", its `eth1`, will sit your entire OpenStack's infrastructure (i.e. `The Cloud`, `Controllers`, `Network` and `Compute Nodes`. And also, the `Instances` and `Regular Servers` or some `KVM Hypervisors` that you might have).

This **Firewall Ubuntu** might have the package **aiccu** installed, so, you'll have at least, one IPv6 /64 block to play with (if you don't have it native from your ISP already, get one from **SixxS.net** and start using it with **aiccu**).

You'll need the package **radvd** installed, so, you'll be able to advertise your IPv6 block(s) within your (V)LAN, including each of your `Project's Instances Network`. And, for your Ubuntu IPv6 clients (including IPv6-Only `Instances`), you'll also need the package **rdnssd** to auto-configure Instance's /etc/resolv.conf file according (it will receive the *DNS Nameservers* from **radvd** on this case).

## 1.1. Gateway (Ubuntu 14.04.2)

Install a Ubuntu 14.04.2 with at least two network cards (can be a small virtual machine).

* Network Topology:

* WAN - eth0

    * IPv6 (If you have native)

        * IP address: 2001:db8:0::2/64
        * Gateway IP: 2001:db8:0::1

    * IPv4

        * IP address: 200.10.1.2/28
        * Gateway IP: 200.10.1.1

* LAN - eth1

    * IPv6 (From SixxS.net, for example)

        * IP addresses: 2001:db8:1::1/64 (Management + Instances)

    * IPv4 (Legacy)

        * IP addresses: 10.0.0.1/24 (Management + Instances)

## 1.2. Example of its /etc/network/interfaces file

Get it here (example):

    curl -s https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/upstream-router/etc/network/interfaces > /etc/network/interfaces

## 1.3. Enable IPv6 / IPv4 packet forwarding

Run the following commands

    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf
    sysctl -p

## 1.4. Upstream IPv6 Router Advertisement (SLAAC)

OpenStack Juno is now compatible with an *upstream router* running radvd.

Get it here (example):

    curl -s https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/upstream-router/etc/radvd.conf > /etc/radvd.conf

Install the following package (RA Daemon):

    sudo apt-get install radvd

Now both your LAN and your Cloud, have IPv6! Have fun!

*NOTE: You'll might want to disable IPv6 Privace Extensions.*

## 1.5. NAT rule (Legacy)

You'll probably need to enable at least, one NAT rule on this environment, so your IPv4 subnet can reach the Internet.

Just run this (better to put it on /etc/rc.local or within /etc/network/interfaces):

    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

*NOTE #1: There is only 1 NAT rule on this environment, which resides on this gateway itself, to do the IPv4 SNAT/DNAT to/from the old Internet infrastructure. There is no IPv4 NAT within this OpenStack environment itself (no Floating IPs, "no multihost=true"). Also, there is no NAT when enjoying the New Internet Powered by IPv6!*

*NOTE #2: If your have more IPv4 public blocks available (i.e. at your gateway's eth1 interface, your Instances can also have public IPs on it! Just like when with IPv6...*

---

# *Inside of the Cloud Computing*

# 2. Deploying the Controller Node

Run this procedure logged in as `root` user.

The OpenStack Controller Node is powered by Ubuntu 14.04.2!

* Requirements:

    * Hostname: controller.yourdomain.com
    * 64 bits O.S. Highly Recommended
    * 1 Virtual Machine (KVM/Xen) with 2G of RAM
    * 1 Virtual Ethernet VirtIO Card
    * 1 Virtual VirtIO HD ~100G (for Ubuntu / Nova / Glance)
    * 1 (Optional) Virtual VirtIO HD ~100G (for Cinder)

* IPv6

    * IP Address: 2001:db8:1::10/64
    * Gateway IP: 2001:db8:1::1

* IPv4 - Legacy

    * IP Address: 10.0.0.10/24
    * Gateway IP: 10.0.0.1

Install Ubuntu 14.04.2 on the first disk, can be the  *Minimum Virtual Machine* flavor, using *Guided LVM Paritioning*, leave the second disk untouched for now (it will be used with Cinder).

## 2.1. Prepare Ubuntu O.S.

Run:

    echo controller > /etc/hostname

    curl -s https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/etc/hosts > /etc/hosts

    apt-get update

    apt-get dist-upgrade -y

    apt-get install vim iptables openvswitch-switch

## 2.2. Configure the network

Get your Controller Node network interfaces file (example):

    curl -s https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/etc/network/interfaces > /etc/network/interfaces

Run:

    ovs-vsctl add-br br-int

    ovs-vsctl add-br br-eth0

The next OVS command will kick you out from this server (if you're connected to it via eth0), that's why we should reboot after running it:

    ovs-vsctl add-port br-eth0 eth0 && reboot

...Otherwise, if you're locally connected at the controller (ttyX), then, you don't need to reboot, just `sudo service networking restart` (I guess). If unsure, then, reboot.

## 2.3. Install OpenStack "base" dependecies

Run:

    apt-get install ubuntu-cloud-keyring software-properties-common

    add-apt-repository cloud-archive:juno

    apt-get update

    apt-get dist-upgrade -y

    apt-get install openssl curl ntp mysql-server python-mysqldb rabbitmq-server python-keyring


Configure it:

Replace `guest` password (syntax is: user / pass, guest / guest).

    rabbitmqctl change_password guest guest

*NOTE: If you replace the RabbitMQ `guest` password, you'll need to update all configuration files manually.*

Reconfigure MySQL by downloading a new `my.cnf`:

    curl -s https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/etc/mysql/my.cnf > /etc/mysql/my.cnf

Restart MySQL:

    service mysql restart

Make your MySQL a bit safer:

    mysql_install_db

    mysql_secure_installation

Pay attention on next step, it will remove all your OpenStack Databases ("factory reset"), before creating it again.

Create/reset the required databases:

    curl -s https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/root/mysql-dbs.sql | mysql -u root -p

### Documentation reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/ch_basic_environment.html#basics-messaging-server
 * http://docs.openstack.org/juno/install-guide/install/apt/content/ch_basic_environment.html#basics-database

## 2.4. Install Keystone

    apt-get install keystone

Download a new `keystone.conf` (it is based on Juno Ubuntu packages, plus a few changes):

    curl -s https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/etc/keystone/keystone.conf > /etc/keystone/keystone.conf

Then run:

    rm /var/lib/keystone/keystone.db

    su -s /bin/sh -c "keystone-manage db_sync" keystone

    service keystone restart

More Keystone stuff:

    cd ~

    wget https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/root/keystone_basic.sh

    wget https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/root/keystone_endpoints_basic.sh

    chmod +x keystone_basic.sh

    chmod +x keystone_endpoints_basic.sh

Create Keystone "basic" stuff and OpenStack's endpoints:

    ./keystone_basic.sh

    ./keystone_endpoints_basic.sh

Preliminary Keystone test

    curl http://controller.yourdomain.com:35357/v2.0/endpoints -H 'x-auth-token: ADMIN' | python -m json.tool

You might want to cleanup your expired tokens with a cronjob, otherwise, your database will increase in size indefinitely. So, do this:

    (crontab -l 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/crontabs/root

Download the `NOVA Resource Configuration` file of your `admin` user:

    cd ~

    wget https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/root/.novarc

Append to your bashrc:

    vi ~/.bashrc

This:

    if [ -f ~/.novarc ]; then
        . ~/.novarc
    fi

Then, load it:

    source ~/.bashrc

Test Keystone with a very basic option to see if it works:

    keystone tenant-list

### Documentation Reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/keystone-install.html

# 3. Install Glance

Lets install Glance

    apt-get install glance python-mysqldb

## 3.1. Configure Glance API

Edit glance-api.conf...

    vi /etc/glance/glance-api.conf

With:

    [DEFAULT]
    bind_host = 2001:db8:1::10

    registry_host = controller.yourdomain.com

    rabbit_host = controller.yourdomain.com

    [database]
    connection = mysql://glanceUser:glancePass@controller.yourdomain.com/glance

    [keystone_authtoken]
    identity_uri = http://controller.yourdomain.com:35357
    auth_uri = http://controller.yourdomain.com:5000
    admin_tenant_name = service
    admin_user = glance
    admin_password = service_pass

    [paste_deploy]
    flavor = keystone

## 3.2. Configure Glance Registry

Edit glance-registry.conf...

    vi /etc/glance/glance-registry.conf

With:

    [DEFAULT]
    bind_host = 2001:db8:1::10

    [database]
    connection = mysql://glanceUser:glancePass@controller.yourdomain.com/glance

    [keystone_authtoken]
    identity_uri = http://controller.yourdomain.com:35357
    auth_uri = http://controller.yourdomain.com:5000
    admin_tenant_name = service
    admin_user = glance
    admin_password = service_pass

    [paste_deploy]
    flavor = keystone

Then run:

    rm /var/lib/glance/glance.sqlite

    su -s /bin/sh -c "glance-manage db_sync" glance

    service glance-api restart; service glance-registry restart

## 3.3. Adding O.S. images into your Glance

Run the following commands to add some O.S. images into your Glance repository.

### 3.3.1. CirrOS (Optional - TestVM):

    glance image-create --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-i386-disk.img --name "CirrOS 0.3.3 - Minimalist - 32-bit - Cloud Based Image" --is-public true --container-format bare --disk-format qcow2

    glance image-create --location http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img --name "CirrOS 0.3.2 - Minimalist - 64-bit - Cloud Based Image" --is-public true --container-format bare --disk-format qcow2

### 3.3.3. Ubuntu 12.04.5 - LTS:

    glance image-create --location http://uec-images.ubuntu.com/releases/12.04.4/release/ubuntu-12.04-server-cloudimg-i386-disk1.img --is-public true --disk-format qcow2 --container-format bare --name "Ubuntu 12.04.5 LTS - Precise Pangolin - 32-bit - Cloud Based Image"

    glance image-create --location http://uec-images.ubuntu.com/releases/12.04.4/release/ubuntu-12.04-server-cloudimg-amd64-disk1.img --is-public true --disk-format qcow2 --container-format bare --name "Ubuntu 12.04.5 LTS - Precise Pangolin - 64-bit - Cloud Based Image"

### 3.3.4. Ubuntu 14.04.2 - LTS:

    glance image-create --location http://uec-images.ubuntu.com/releases/14.04.2/release/ubuntu-14.04-server-cloudimg-i386-disk1.img --is-public true --disk-format qcow2 --container-format bare --name "Ubuntu 14.04.2 LTS - Trusty Tahr - 32-bit - Cloud Based Image"

    glance image-create --location http://uec-images.ubuntu.com/releases/14.04.2/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img --is-public true --disk-format qcow2 --container-format bare --name "Ubuntu 14.04.2 LTS - Trusty Tahr - 64-bit - Cloud Based Image"

### 3.3.5. Ubuntu 14.10:

    glance image-create --location http://uec-images.ubuntu.com/releases/14.10/release/ubuntu-14.10-server-cloudimg-i386-disk1.img --is-public true --disk-format qcow2 --container-format bare --name "Ubuntu 14.10 - Utopic Unicorn - 32-bit - Cloud Based Image"

    glance image-create --location http://uec-images.ubuntu.com/releases/14.10/release/ubuntu-14.10-server-cloudimg-amd64-disk1.img --is-public true --disk-format qcow2 --container-format bare --name "Ubuntu 14.10 - Utopic Unicorn - 64-bit - Cloud Based Image"

### 3.3.5. CoreOS 493.0.0

Info: https://coreos.com

    cd ~

    wget http://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2

    bunzip2 coreos_production_openstack_image.img.bz2

    glance image-create --name "CoreOS 493.0.0 - Linux 3.17.2 - Docker 1.3.1 - etcd 0.4.6 - fleet 0.8.1" --container-format ovf --disk-format qcow2 --file coreos_production_openstack_image.img --is-public True

### 3.3.6. Windows 2012 R2:

If you need to run Windows 2012 in your OpenStack, visit: http://cloudbase.it/ws2012r2 to download the image "windows_server_2012_r2_standard_eval_kvm_20140607.qcow2.gz", then, run:

    gunzip /root/windows_server_2012_r2_standard_eval_kvm_20140607.qcow2.gz

    glance image-create --name "Windows Server 2012 R2 Standard Eval" --container-format bare --disk-format qcow2 --is-public true < /root/windows_server_2012_r2_standard_eval_kvm_20140607.qcow2

### 3.4. Listing the O.S. images:

    glance image-list

### Documentation Reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/glance-install.html

# 4. Install Nova

Run:

    apt-get install python-novaclient nova-api nova-cert nova-consoleauth nova-scheduler nova-conductor nova-spiceproxy

## 4.1. Configure Nova

Run:

    cd /etc/nova

    mv /etc/nova/nova.conf /etc/nova/nova.conf_Ubuntu

    wget https://gist.githubusercontent.com/tmartinx/10784491/raw/384356d1b072d1a65f4c9175a26e4154e4d97079/nova.conf

    chown nova: /etc/nova/nova.conf

    chmod 640 /etc/nova/nova.conf

    rm /var/lib/nova/nova.sqlite

*NOTE: Edit your nova.conf file, before running "db sync", to reflect your own FQDN (*.yourdomain.com) and IPv6 address, if desired.*

    su -s /bin/sh -c "nova-manage db sync" nova

Now, you can restart all Nova services:

    cd /etc/init/; for i in $(ls nova-* | cut -d \. -f 1 | xargs); do sudo service $i restart; done

## 4.2. Personalize your flavors (optional):

Delete the default examples:

    nova flavor-delete 1
    nova flavor-delete 2
    nova flavor-delete 3
    nova flavor-delete 4
    nova flavor-delete 5

Create new flavors (Storage / Hard Disk):

    # Standard Flavor
    nova flavor-create --ephemeral 0 --swap 128 --rxtx-factor 1.0 --is-public yes m1.micro 1 256 5 1
    nova flavor-create --ephemeral 25 --swap 256 --rxtx-factor 1.0 --is-public yes m1.tiny 2 512 10 1
    nova flavor-create --ephemeral 50 --swap 512 --rxtx-factor 1.0 --is-public yes m1.small 3 1024 10 1
    nova flavor-create --ephemeral 100 --swap 1024 --rxtx-factor 1.0 --is-public yes m1.medium 4 2048 10 2
    nova flavor-create --ephemeral 200 --swap 2048 --rxtx-factor 1.0 --is-public yes m1.large 5 4096 10 4
    nova flavor-create --ephemeral 400 --swap 4096 --rxtx-factor 1.0 --is-public yes m1.xlarge 6 8192 10 8

    # CPU optmized
    nova flavor-create --ephemeral 50 --swap 512 --rxtx-factor 1.0 --is-public yes c1.small 7 1024 10 2
    nova flavor-create --ephemeral 50 --swap 1024 --rxtx-factor 1.0 --is-public yes c1.medium 8 2048 10 4
    nova flavor-create --ephemeral 50 --swap 2048 --rxtx-factor 1.0 --is-public yes c1.large 9 4096 10 8
    nova flavor-create --ephemeral 50 --swap 4096 --rxtx-factor 1.0 --is-public yes c1.xlarge 10 8192 10 16

    # RAM Memory optimized
    nova flavor-create --ephemeral 0 --swap 256 --rxtx-factor 1.0 --is-public yes r1.micro 11 512 5 1
    nova flavor-create --ephemeral 25 --swap 512 --rxtx-factor 1.0 --is-public yes r1.tiny 12 1024 10 1
    nova flavor-create --ephemeral 50 --swap 1024 --rxtx-factor 1.0 --is-public yes r1.small 13 2048 10 1
    nova flavor-create --ephemeral 100 --swap 2048 --rxtx-factor 1.0 --is-public yes r1.medium 14 4096 10 2
    nova flavor-create --ephemeral 200 --swap 4096 --rxtx-factor 1.0 --is-public yes r1.large 15 8192 10 4
    nova flavor-create --ephemeral 400 --swap 8192 --rxtx-factor 1.0 --is-public yes r1.xlarge 16 16384 10 8

    # Storage optimized
    nova flavor-create --ephemeral 50 --swap 256 --rxtx-factor 1.0 --is-public yes s1.tiny 17 512 10 1
    nova flavor-create --ephemeral 100 --swap 512 --rxtx-factor 1.0 --is-public yes s1.small 18 1024 10 1
    nova flavor-create --ephemeral 200 --swap 1024 --rxtx-factor 1.0 --is-public yes s1.medium 19 2048 20 2
    nova flavor-create --ephemeral 400 --swap 2048 --rxtx-factor 1.0 --is-public yes s1.large 20 4096 40 4
    nova flavor-create --ephemeral 800 --swap 4096 --rxtx-factor 1.0 --is-public yes s1.xlarge 21 8192 80 8

    # Windows optimized
    nova flavor-create --ephemeral 100 --swap 0 --rxtx-factor 1.0 --is-public yes w1.small 22 1024 20 1
    nova flavor-create --ephemeral 200 --swap 0 --rxtx-factor 1.0 --is-public yes w1.medium 23 2048 20 2
    nova flavor-create --ephemeral 400 --swap 0 --rxtx-factor 1.0 --is-public yes w1.large 24 4096 40 4
    nova flavor-create --ephemeral 800 --swap 0 --rxtx-factor 1.0 --is-public yes w1.xlarge 25 8192 40 8

Create new flavors (Storage / SSD):

    # Standard Flavor
    nova flavor-create --ephemeral 0 --swap 128 --rxtx-factor 1.0 --is-public yes m3.micro 26 256 5 1
    nova flavor-create --ephemeral 5 --swap 256 --rxtx-factor 1.0 --is-public yes m3.tiny 27 512 10 1
    nova flavor-create --ephemeral 10 --swap 512 --rxtx-factor 1.0 --is-public yes m3.small 28 1024 10 1
    nova flavor-create --ephemeral 20 --swap 1024 --rxtx-factor 1.0 --is-public yes m3.medium 29 2048 10 2
    nova flavor-create --ephemeral 40 --swap 2048 --rxtx-factor 1.0 --is-public yes m3.large 30 4096 10 4
    nova flavor-create --ephemeral 80 --swap 4096 --rxtx-factor 1.0 --is-public yes m3.xlarge 31 8192 10 8

    # Windows optimized
    nova flavor-create --ephemeral 10 --swap 0 --rxtx-factor 1.0 --is-public yes w3.small 32 1024 20 1
    nova flavor-create --ephemeral 20 --swap 0 --rxtx-factor 1.0 --is-public yes w3.medium 33 2048 20 2
    nova flavor-create --ephemeral 40 --swap 0 --rxtx-factor 1.0 --is-public yes w3.large 34 4096 40 4
    nova flavor-create --ephemeral 80 --swap 0 --rxtx-factor 1.0 --is-public yes w3.xlarge 35 8192 40 8

*NOTE: Soon as possible, I'll introduce Host Aggregates, when instances based on SSD disks will be deployed on Compute Nodes that have SSD, using this feature.*

### Documentation Reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/ch_nova.html

# 5. Install Neutron

Run:

    apt-get install neutron-server neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-dhcp-agent neutron-metadata-agent

## 5.1. Configure Neutron

First, take a note of the "Service Tenant ID" with:

    keystone tenant-get service

Edit neutron.conf...

    vi /etc/neutron/neutron.conf

With:

    [DEFAULT]
    bind_host = 2001:db8:1::10
    auth_strategy = keystone
    allow_overlapping_ips = True
    rabbit_host = controller.yourdomain.com
    rpc_backend = rabbit
    core_plugin = ml2
    service_plugins = router

    notify_nova_on_port_status_changes = True
    notify_nova_on_port_data_changes = True
    nova_url = http://controller.yourdomain.com:8774/v2
    nova_region_name = RegionOne
    nova_admin_username = nova
    nova_admin_tenant_id = $SERVICE_TENANT_ID
    nova_admin_password = service_pass
    nova_admin_auth_url = http://controller.yourdomain.com:35357/v2.0

    [keystone_authtoken]
    auth_uri = http://controller.yourdomain.com:5000
    identity_uri = http://controller:35357
    admin_tenant_name = service
    admin_user = neutron
    admin_password = service_pass
    signing_dir = $state_path/keystone-signing

    [database]
    connection = mysql://neutronUser:neutronPass@controller.yourdomain.com/neutron

Edit ml2_conf.ini...

    vi /etc/neutron/plugins/ml2/ml2_conf.ini

With:

    [ml2]
    type_drivers = local,flat

    mechanism_drivers = openvswitch,l2population

    [ml2_type_flat]
    flat_networks = *

    [securitygroup]
    enable_security_group = True
    firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
    enable_ipset = True

    [ovs]
    enable_tunneling = False
    local_ip = 10.0.0.11
    network_vlan_ranges = physnet1
    bridge_mappings = physnet1:br-eth0

Edit metadata_agent.ini...

    vi /etc/neutron/metadata_agent.ini

With:

    # The Neutron user information for accessing the Neutron API.
    auth_url = http://controller.yourdomain.com:5000/v2.0
    auth_region = RegionOne
    # Turn off verification of the certificate for ssl
    # auth_insecure = False
    # Certificate Authority public key (CA cert) file for ssl
    # auth_ca_cert =
    admin_tenant_name = service
    admin_user = neutron
    admin_password = service_pass

    nova_metadata_ip = 10.0.0.11
    nova_metadata_port = 8775
    metadata_proxy_shared_secret = metasecret13

Edit dhcp_agent.ini...

    vi /etc/neutron/dhcp_agent.ini

With:

    [DEFAULT]
    interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver

    use_namespaces = True

    enable_isolated_metadata = True

    dhcp_domain = yourdomain.com

Run:

    su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade juno" neutron

    cd /etc/init/; for i in $(ls -1 neutron-* | cut -d \. -f 1); do sudo service $i restart; done

## 5.2. Create the OpenStack Neutron Network

For the sake of simplicity, both management and instances networks, share the same IPv6 and IPv4 subnet. They are Dual-Stacked but, IPv4 is entirely optional, if you have IPv6.

When with IPv6, the life is easier, just enable `SLAAC` in your Network. Then, both Nodes (Management Network) and Instances will generate its own IPv6 address automatically, you'll want DNS here, or at least, a well configured `/etc/hosts` files. Plus, you might want to disable `IPv6 Privacy Extensions` within your Instances, since OpenStack Neutron does not have support for it.

When with IPv4, the subnet `10.0.0.0/24` is subdivided into two, not by subnet mask, but instead, by using the Neutron option "--allocation-pool". So, from `10.0.0.1` to `10.0.0.128`, resides the some `KVM Hypervisors` (`ubuntu-virt`) running things like the Gateway, Controler and Network nodes, also the Compute Nodes are others `KVM Hypervisors` running `nova-compute` and `Neutron OVS Agent`. And for your `Instances`, from `10.0.0.129` to `10.0.0.254`.

So, it is simpler, you just need one `Single Flat Network`, `Dual-Stacked`, IPv4 with DHCPv4 and IPv6 with SLAAC, for your entire Cloud Computing.

Also, since we aren't using Neutron acting as a L3 Router, we don't need to deal with any extra IPv6/4 subnets. Remember, just one IPv6 (or IPv4) subnet is enough to start using OpenStack, very minimalist and stable. Then you can start playing with `VLAN Provider Networks` and later, with topologies like `Per-Tenant Router with Private Networks`, just like the `docs.openstack.org/juno` presents.

### 5.2.1. Creating the Flat Neutron Network

First, get the admin tenant id and note it (like var $ADMIN_TENTANT_ID).

    keystone tenant-list

Mapping the physical network, that one from your "upstream router", into OpenStack Neutron:

    neutron net-create --tenant-id $ADMIN_TENTANT_ID sharednet1 --shared --provider:network_type flat --provider:physical_network physnet1

Create an IPv4 subnet on "sharednet1":

    neutron subnet-create --ip-version 4 --tenant-id $ADMIN_TENANT_ID sharednet1 10.0.0.0/24 --allocation-pool start=10.0.0.129,end=10.0.0.254 --dns_nameservers list=true 8.8.4.4 8.8.8.8

Create an IPv6 subnet on "sharednet1":

    neutron subnet-create --ip-version 6 --ipv6_address_mode=slaac --tenant-id $ADMIN_TENANT_ID sharednet1 2001:db8:1::/64

### Documentation Reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/neutron-controller-node.html

# 6. Install Cinder

## 6.1. Cinder API / endpoint access:

    apt-get install cinder-api cinder-scheduler python-mysqldb

    curl -s https://raw.githubusercontent.com/tmartinx/openstack-guides/master/Juno/controller/etc/cinder/cinder.conf > /etc/cinder/cinder.conf

Run:

    su -s /bin/sh -c "cinder-manage db sync" cinder

    cd /etc/init/; for i in $(ls cinder-* | cut -d \. -f 1 | xargs); do sudo service $i restart; done

## 6.2. Cinder iSCSI block storage service

This procedure will make use of the extra Virtual HD of your controller.yourdomain.com (about 100G).

*If don't have it, add one: halt VM -> go to "virt-manager" -> Add hardware -> VirtIO Disk / 100G / RAW.*

Then start it again and run:

    # Create a primary partition on it, type LVM (8e)
    cfdisk /dev/vdb

    # Create the LVM Physical Volume
    pvcreate /dev/vdb1

    # Create the LVM Volume Group
    vgcreate cinder-volumes /dev/vdb1

Install Cinder Volume (optional):

    apt-get install cinder-volume

### Documentation Reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/cinder-install-controller-node.html

# 7. Install Horizon Dashboard

Run:

    apt-get install openstack-dashboard memcached

    apt-get purge openstack-dashboard-ubuntu-theme

Edit Dashboard config file:

    vi /etc/openstack-dashboard/local_settings.py

With:

    OPENSTACK_HOST = "controller.yourdomain.com"

Run:

    service apache2 restart ; service memcached restart

Done! You can try to access the Dashboard to test admin login...

### Documentation Reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/install_dashboard.html

---

# 8. Deploying your first Compute Node

This OpenStack Compute Node is powered by Ubuntu 14.04.2!

* Requirements:1 Physical Server with Virtualization support on CPU, 1 ethernet

    * 1 Physical Server with Virtualization support on CPU
    * 1 Ethernet Card
    * 1 HardDisk about 500G
    * Hostname: compute-1.yourdomain.com
    * 64 bits O.S. highly recommended

* IPv6

    * IP address: 2001:db8:1::20/64
    * Gateway IP: 2001:db8:1::1

* IPv4 - Legacy

    * IP address: 10.0.0.31/24
    * Gateway IP: 10.0.0.1

## 8.1. Install Ubuntu 14.04.2

This installation can be the "Minimum Installation" flavor, using `Manual Paritioning', make the following partitions:

* /dev/sda1 on /boot (~256M - /dev/md0 if raid1[0], bootable)
* /dev/sda2 on LVM VG vg01 (~50G - /dev/md1 if raid1[0]) - lv_root (25G), lv_swap (XG) of compute-1
* /dev/sda3 on LVM VG nova-local (~450G - /dev/md2 if raid1[0]) - Instances

Login as root and run:

    echo compute-1 > /etc/hostname

    apt-get update

    apt-get install ubuntu-cloud-keyring software-properties-common

    add-apt-repository cloud-archive:juno

    apt-get update

    apt-get dist-upgrade -y

    # If your kernel gets upgraded, do a reboot before running the next command:

    apt-get install linux-image-extra-`uname -r` vim iptables ipset ubuntu-virt-server libvirt-bin pm-utils nova-compute-kvm python-guestfs neutron-plugin-openvswitch-agent openvswitch-switch -y

When prompted to create a *supermin* appliance, respond **yes**.

make the current kernel readable (BUG LP #759725):

    dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-$(uname -r)

Remove pre-configured libvirt default network:

    virsh net-destroy default

    virsh net-undefine default

## 8.2. Configure your Ubuntu KVM Hypervisor

Run:

    # Enable vhost_net module:
    sed -i 's/^VHOST_NET_ENABLED=0/VHOST_NET_ENABLED=1/' /etc/default/qemu-kvm

    # Prepare /etc/libvirt/libvirtd.conf:
    sed -i 's/^#listen_tls = 0/listen_tls = 0/' /etc/libvirt/libvirtd.conf

    sed -i 's/^#listen_tcp = 1/listen_tcp = 1/' /etc/libvirt/libvirtd.conf

    sed -i 's/^#auth_tcp = "sasl"/auth_tcp = "none"/' /etc/libvirt/libvirtd.conf

    # Prepare /etc/init/libvirt-bin.conf:
    sed -i 's/^env libvirtd_opts="-d"/env libvirtd_opts="-d -l"/' /etc/init/libvirt-bin.conf

    # Prepare /etc/default/libvirt-bin:
    sed -i 's/^libvirtd_opts="-d"/libvirtd_opts="-d -l"/' /etc/default/libvirt-bin

## 8.3. Configure the network

Edit:

    vi /etc/hosts

With:

    127.0.0.1       localhost.localdomain   localhost

    # IPv6
    2001:db8:1::10  controller.yourdomain.com   controller
    2001:db8:1::20  compute-1.yourdomain.com   compute-1
    2001:db8:1::30  compute-2.yourdomain.com   compute-2

    # IPv4 - Not needed:
    #10.0.0.11    controller.yourdomain.com   controller
    #10.0.0.31    compute-1.yourdomain.com   compute-1
    #10.0.0.41    compute-2.yourdomain.com   compute-2

Edit:

    vi /etc/network/interfaces

With:

    # The primary network interface
    # ETH0 - BEGIN
    auto eth0
    iface eth0 inet manual
            up ip link set $IFACE up
            up ip address add 0/0 dev $IFACE
            down ip link set $IFACE down
    # ETH0 - END

    # BR-ETH0 - BEGIN
    auto br-eth0

    # IPv6
    iface br-eth0 inet6 static
    	address 2001:db8:1::20
    	netmask 64
        gateway 2001:db8:1::1
    	# dns-* options are implemented by the resolvconf package, if installed
    	dns-domain yourdomain.com
        dns-search yourdomain.com
        # Google Public DNS
        dns-nameservers 2001:4860:4860::8844 2001:4860:4860::8888
        # OpenNIC
    #    dns-nameservers 2001:530::216:3cff:fe8d:e704 2600:3c00::f03c:91ff:fe96:a6ad 2600:3c00::f03c:91ff:fe96:a6ad
        # OpenDNS Public Name Servers:
    #    dns-nameservers 2620:0:ccc::2 2620:0:ccd::2

    # IPv4 - Legacy
    iface br-eth0 inet static
        address 10.0.0.31
        netmask 24
        gateway 10.0.0.1
        # Google Public DNS
    	dns-nameservers 8.8.4.4
        # OpenDNS
    #    dns-nameservers 208.67.222.222 208.67.220.220 208.67.222.220 208.67.220.222
        # OpenNIC
    #    dns-nameservers 66.244.95.20 74.207.247.4 216.87.84.211
    # BR-ETH0 - END

Run:

    ovs-vsctl add-br br-int

    ovs-vsctl add-br br-eth0

The next OVS command will kick you out from this server (if connected to it via eth0), that's why we should reboot after running it:

    ovs-vsctl add-port br-eth0 eth0 && reboot

## 8.4. Configure Nova:

Run:

    mv /etc/nova/nova.conf /etc/nova/nova.conf_Ubuntu

    cd /etc/nova

    wget https://gist.githubusercontent.com/tmartinx/10784896/raw/8088aee54877caca18c3020f91b662cdea627213/nova.conf

    chown nova: /etc/nova/nova.conf

    chmod 640 /etc/nova/nova.conf

    cd /etc/init/; for i in $(ls nova-* | cut -d \. -f 1 | xargs); do sudo service $i restart; done

### Documentation Reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/ch_nova.html#nova-compute-install

## 8.5. Install Neutron

NOTE: Run this command on compute-1.yourdomain.com, not on controller.yourdomain.com.

Edit:

    vi /etc/neutron/neutron.conf

With:

    [DEFAULT]
    # debug = True
    # verbose = True
    allow_overlapping_ips = True
    rabbit_host = controller.yourdomain.com

    notify_nova_on_port_status_changes = True
    notify_nova_on_port_data_changes = True
    nova_url = http://controller.yourdomain.com:8774/v2
    nova_region_name = RegionOne
    nova_admin_username = nova
    nova_admin_tenant_id = $SERVICE_TENANT_ID
    nova_admin_password = service_pass
    nova_admin_auth_url = http://controller.yourdomain.com:35357/v2.0

    [keystone_authtoken]
    auth_uri = http://controller.yourdomain.com:5000
    auth_host = controller.yourdomain.com
    auth_port = 35357
    auth_protocol = http
    admin_tenant_name = service
    admin_user = neutron
    admin_password = service_pass
    signing_dir = /var/lib/neutron/keystone-signing

    [database]
    connection = mysql://neutronUser:neutronPass@controller.yourdomain.com/neutron

Edit:

    vi /etc/neutron/plugins/ml2/ml2_conf.ini

With:

    [ml2]
    type_drivers = local,flat

    mechanism_drivers = openvswitch,l2population

    [ml2_type_flat]
    flat_networks = *

    [securitygroup]
    enable_security_group = True
    firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
    enable_ipset = True

    [ovs]
    enable_tunneling = False
    local_ip = 10.0.0.31
    network_vlan_ranges = physnet1
    bridge_mappings = physnet1:br-eth0

Run:

    service neutron-plugin-openvswitch-agent restart

### Documentation Reference

 * http://docs.openstack.org/juno/install-guide/install/apt/content/neutron-compute-node.html

# 9. Creating your first Dual-Stacked Instance

Now, go back to the node `controller.yourdomain.com` and run the following commands as root:

Show the O.S. images to get the IDs:

    glance image-list

Boot your Ubuntu 14.04.2 - 32-bit fits better on m1.micro:

    nova boot --image $your_ubuntu_14.04.2_lts_image_id --key-name my_ssh_key --flavor 1 ubuntu-1

The above command will create your Instance but, the IPv6 address will not be configured automatically within it, so, do the following steps to enable it:

Get Instance's info:

    nova list

Something like this will appear:

    +--------------------------------------+-------------+--------+------------+-------------+----------------------------------------------+
    | ID                                   | Name        | Status | Task State | Power State | Networks                                     |
    +--------------------------------------+-------------+--------+------------+-------------+----------------------------------------------+
    | 0460d770-372a-4549-80db-ccbafddda22c | ubuntu-1    | ACTIVE | -          | Running     | sharednet1=2001:db8:1::8000, 10.0.0.130    |
    +--------------------------------------+-------------+--------+------------+-------------+----------------------------------------------+

Go there and configure the IPv6 statically:

    ssh ubuntu@10.0.0.130
    sudo ip -6 a a 2001:db8:1::8000/64 dev eth0
    sudo ip -6 r a default via 2001:db8:1::1

Verify IPv6 connectivity:

    ubuntu@ubuntu-1:~$ ping6 -c1 google.com
    PING google.com(2800:3f0:4004:800::1001) 56 data bytes
    64 bytes from 2800:3f0:4004:800::1001: icmp_seq=1 ttl=52 time=36.2 ms

Now, to make it persistent across Instance's reboots, do this:

Edit the interfaces configuration file:

    vi /etc/network/interfaces.d/eth0.cfg

With:

    # The primary network interface
    auto eth0
    iface eth0 inet dhcp

    iface eth0 inet6 static
            address 2001:db8:1::8000
            netmask 64
            gateway 2001:db8:1::1

*NOTE: The IPv6 subnet 2001:db8:1::/64 is ONLY used for documentation purposes, it will not be routed. So, replace it with your own block, for example, the one from SixxS.net.*

# Well Done!

Point mycloud.yourdomain.com to 2001:db8:1::10 (and/or 10.0.0.11) and open
the *Horizon Dashboard* at:

http://mycloud.yourdomain.com/horizon - user admin, pass admin_pass

**Congratulations!!**

You have your own Private Cloud Computing Environment up and running! With IPv6!!

*Enjoy it!*

# 10. TODO List

* Ubuntu Flex container
* Heat
* Ceilometer
* Trove
* Host Aggregates
* Docker.io on Heat & Nova
* Swift
* Enable Sound Device for Instances

# 11. References

- OpenStack Juno Documentation for Ubuntu:

 http://docs.openstack.org/juno/install-guide/install/apt/content/

- OpenStack `Single Flat Network` documentation:

 http://docs.openstack.org/trunk/install-guide/install/apt/content/section_use-cases-single-flat.html

- OpenStack `Multi Flat Network` documentation:

 http://docs.openstack.org/trunk/install-guide/install/apt/content/section_use-cases-multi-flat.html

# 12. Limitations

* Only 1 Ethernet per physical server (if you don't build BOND channels or deploy it with more Ethernet segments, it might be a bottleneck for production environments).

# 13. Features

* No NAT within this Cloud, no *Floating IPs*, no *multihost=true* (i.e. no NAT at the Compute Node itself).

# 14. Observations

## 14.1. About upstream router

The "upstream router" is located outside of OpenStack's control, it is dual-stacked, and the default route for both physical serves and instances. This means that we're *mapping our physical network into OpenStack*, using ML2 plugin with *Single Flat Network* topology (also *VLAN Provider Network* is supported).

## 14.2. About IPv6

For tenant's subnet, the "border gateway / external router" have the IPv6 Router Advertisement daemon running on it (radvd), so, the instances can use it using "Upstream IPv6 RA / SLAAC".

## 14.3. About IPv4

When using OpenStack Juno, there is only one place that IPv4 is still required: For the Metadata Network. So, the tenants still needs IPv4 connectivity, just to put Metadata to work. This will be required until `cloud-init`, and OpenStack itself, doesn't provides "Metadata over IPv6" support.

*NOTE: Now with Juno, there is a new Metadata option, called "Config Drive", it seems to be possible to use it in place of current IPv4 subnet (169.254.169.254). I'll try it soon!*

Everything else, is IPv6-Only, as expected.

Nevertheless, if you don't want to play with IPv6, you can safely replace all IPv6 address of this guide, with your IPv4, everything will work as expected.

## 14.4. About NAT

My idea is to move on and forget about IPv4 and NAT tables, so, with IPv6, we don't need NAT anymore. NAT66 is a bad thing (from my point of view), be part of the real Internet with IPv6 address from the subnet 2000::/3! Again, **do not use** "ip6tables -t nat", unless you want to break your network, and the Internet itself.

One last word about NAT: it breaks the end-to-end Internet connectivity, effectively kicking you out from the real Internet, and it is just a workaround created to deal with the IPv4 exhaustion, so, there is no need for NAT(66) on an IPv6-World.

## 14.5. About configuration files

The configuration files that you downloaded using `curl -s` are the complete original files, from Ubuntu Cloud Archive packages, plus our customizations.

You can easily see the differences between the files from the guide, with the files from the packages, just use `diff -Nru /etc/neutron/neutron.conf juno-guide-example-neutron.conf`.

You might want to replace the domain `yourdomain.com` with your own real `domain.com`.

By Thiago Martins <thiagocmartinsc@gmail.com>
