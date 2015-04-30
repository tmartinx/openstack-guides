#!/bin/sh
#
# Keystone basic configuration
#
# Mainly inspired by https://github.com/openstack/keystone/blob/master/tools/sample_data.sh
#
# Modified by Bilel Msekni / Institut Telecom
#
# Modified by Thiago Martins - Added Ceilometer, Swift and Heat basic keystone info
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#
# Documentation Reference
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/keystone-users.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/glance-install.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/nova-controller.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/neutron-ml2-controller-node.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/cinder-controller.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/general-installation-steps-swift.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/heat-install.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/ceilometer-install.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/trove-install.html

# Host IP address, hostname or FQDN - Can resolve to an IPv6 address as well
HOST_IP=controller.yourdomain.com

ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin_pass}
DEMO_PASSWORD=${DEMO_PASSWORD:-demo_pass}
SERVICE_PASSWORD=${SERVICE_PASSWORD:-service_pass}

export SERVICE_TOKEN="ADMIN"
export SERVICE_ENDPOINT="http://${HOST_IP}:35357/v2.0"

SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}

get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}

# Tenants
ADMIN_TENANT=$(get_id keystone tenant-create --name=admin --description="Admin_Tenant")
SERVICE_TENANT=$(get_id keystone tenant-create --name=$SERVICE_TENANT_NAME --description="Service_Tenant")
DEMO_TENANT=$(get_id keystone tenant-create --name=demo --description="Demo_Tenant")

# Users
ADMIN_USER=$(get_id keystone user-create --name=admin --pass="$ADMIN_PASSWORD" --email=admin@yourdomain.com)
DEMO_USER=$(get_id keystone user-create --name=demo --pass="$DEMO_PASSWORD" --email=demo@yourdomain.com)

# Roles
ADMIN_ROLE=$(get_id keystone role-create --name=admin)
KEYSTONEADMIN_ROLE=$(get_id keystone role-create --name=KeystoneAdmin)
KEYSTONESERVICE_ROLE=$(get_id keystone role-create --name=KeystoneServiceAdmin)
HEAT_ROLE=$(get_id keystone role-create --name=heat_stack_user)

# The Member role is used by Horizon and Swift.
# By default, the Identity Service creates a special _member_ role. The
# OpenStack dashboard automatically grants access to users with this role. You
# will give the admin user access to this role in addition to the admin role.
#MEMBER_ROLE=$(get_id keystone role-create --name=_member_)

# Add Roles to Users in Tenants
keystone user-role-add --user $ADMIN_USER --role $ADMIN_ROLE --tenant $ADMIN_TENANT
keystone user-role-add --user $ADMIN_USER --role _member_ --tenant $ADMIN_TENANT
keystone user-role-add --user $DEMO_USER --role _member_ --tenant $DEMO_TENANT
keystone user-role-add --user $ADMIN_USER --role $KEYSTONEADMIN_ROLE --tenant $ADMIN_TENANT
keystone user-role-add --user $ADMIN_USER --role $KEYSTONESERVICE_ROLE --tenant $ADMIN_TENANT

# Configure service users/roles
GLANCE_USER=$(get_id keystone user-create --name=glance --pass="$SERVICE_PASSWORD" --email=glance@yourdomain.com)
keystone user-role-add --user $GLANCE_USER --tenant $SERVICE_TENANT --role $ADMIN_ROLE

NOVA_USER=$(get_id keystone user-create --name=nova --pass="$SERVICE_PASSWORD" --email=nova@yourdomain.com)
keystone user-role-add --user $NOVA_USER --tenant $SERVICE_TENANT --role $ADMIN_ROLE

NEUTRON_USER=$(get_id keystone user-create --name=neutron --pass="$SERVICE_PASSWORD" --email=neutron@yourdomain.com)
keystone user-role-add --user $NEUTRON_USER --tenant $SERVICE_TENANT --role $ADMIN_ROLE

CINDER_USER=$(get_id keystone user-create --name=cinder --pass="$SERVICE_PASSWORD" --email=cinder@yourdomain.com)
keystone user-role-add --user $CINDER_USER --tenant $SERVICE_TENANT --role $ADMIN_ROLE

SWIFT_USER=$(get_id keystone user-create --name=swift --pass="$SERVICE_PASSWORD" --email=swift@yourdomain.com)
keystone user-role-add --user $SWIFT_USER --tenant $SERVICE_TENANT --role $ADMIN_ROLE

HEAT_USER=$(get_id keystone user-create --name=heat --pass="$SERVICE_PASSWORD" --email heat@yourdomain.com)
keystone user-role-add --user $HEAT_USER --tenant $SERVICE_TENANT --role $ADMIN_ROLE

CEILOMETER_USER=$(get_id keystone user-create --name=ceilometer --pass="$SERVICE_PASSWORD" --email=ceilometer@yourdomain.com)
keystone user-role-add --user $CEILOMETER_USER --tenant $SERVICE_TENANT --role $ADMIN_ROLE

TROVE_USER=$(get_id keystone user-create --name=trove --pass="$SERVICE_PASSWORD" --email trove@yourdomain.com)
keystone user-role-add --user $TROVE_USER --tenant $SERVICE_TENANT --role $ADMIN_ROLE

# Ceilometer needs ResellerAdmin role to access swift account stats
RESELLER_ROLE=$(get_id keystone role-create --name=ResellerAdmin)
keystone user-role-add --tenant-id $SERVICE_TENANT --user-id $CEILOMETER_USER --role-id $RESELLER_ROLE
