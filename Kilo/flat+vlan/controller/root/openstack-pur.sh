#! /bin/sh
#
# Create projects, users, and roles
#
# Mainly inspired by https://github.com/openstack/keystone/blob/master/tools/sample_data.sh
#
# Modified by Bilel Msekni / Institut Telecom
#
# Modified by Thiago Martins - Kilo
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#
# Documentation Reference:
#
# http://docs.openstack.org/kilo/install-guide/install/apt/content/keystone-users.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/glance-install.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/ch_nova.html#nova-controller-install
# http://docs.openstack.org/kilo/install-guide/install/apt/content/neutron-controller-node.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/cinder-install-controller-node.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/swift-install-controller-node.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/heat-install-controller-node.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/ceilometer-controller-install.html
# ** Trove docs and packages missing ***

export LC_ALL=C

# Host IP address, hostname or FQDN - Can resolve to an IPv6 address too:
HOST_ADDR=controller.yourdomain.com

ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin_pass}
SERVICE_PASSWORD=${SERVICE_PASSWORD:-service_pass}
DEMO_PASSWORD=${DEMO_PASSWORD:-demo_pass}

export OS_TOKEN="ADMIN_TOKEN"
export OS_URL="http://${HOST_ADDR}:35357/v2.0"

# OpenStack basic Projects and Users and Roles:
openstack project create --description "Admin Project" admin
openstack user create --password "$ADMIN_PASSWORD" --email admin@yourdomain.com admin
openstack role create admin
openstack role add --project admin --user admin admin

openstack project create --description "Service Project" service

openstack project create --description "Demo Project" demo
openstack user create --password "$DEMO_PASSWORD" --email demo@yourdomain.com demo

openstack role create user
openstack role add --project demo --user demo user

# NOTE: OpenStack documentation doesn't tell us to create the "_member_" role anymore:
#openstack role create _member_
#openstack role add --project demo --user demo _member_

openstack user create --password "$SERVICE_PASSWORD" --email glance@yourdomain.com glance
openstack role add --project service --user glance admin

openstack user create --password "$SERVICE_PASSWORD" --email nova@yourdomain.com nova
openstack role add --project service --user nova admin

openstack user create --password "$SERVICE_PASSWORD" --email neutron@yourdomain.com neutron
openstack role add --project service --user neutron admin

openstack user create --password "$SERVICE_PASSWORD" --email cinder@yourdomain.com cinder
openstack role add --project service --user cinder admin

openstack user create --password "$SERVICE_PASSWORD" --email swift@yourdomain.com swift
openstack role add --project service --user swift admin

openstack user create --password "$SERVICE_PASSWORD" --email heat@yourdomain.com heat
openstack role add --project service --user heat admin

openstack role create heat_stack_owner
openstack role add --project demo --user demo heat_stack_owner

openstack role create heat_stack_user

openstack user create --password "$SERVICE_PASSWORD" --email ceilometer@yourdomain.com ceilometer
openstack role add --project service --user ceilometer admin

openstack user create --password "$SERVICE_PASSWORD" --email trove@yourdomain.com trove
openstack role add --project service --user trove admin
