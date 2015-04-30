#!/bin/sh
#
# Keystone basic Endpoints
#
# Mainly inspired by https://github.com/openstack/keystone/blob/master/tools/sample_data.sh
#
# Modified by Bilel Msekni / Institut Telecom
#
# Modified by Thiago Martins - Added Ceilometer and Swift basic info
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#
# Documentation Reference:
#
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/keystone-services.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/glance-install.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/nova-controller.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/neutron-controller-node.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/cinder-controller.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/general-installation-steps-swift.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/heat-install.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/ceilometer-install.html
# http://docs.openstack.org/icehouse/install-guide/install/apt/content/trove-install.html

# Host IP address, hostname or FQDN - Can resolve to a IPv6 address too
HOST_IP=controller.yourdomain.com
EXT_HOST_IP=controller.yourdomain.com

# MySQL definitions
MYSQL_USER=keystoneUser
MYSQL_DATABASE=keystone
MYSQL_HOST=$HOST_IP
MYSQL_PASSWORD=keystonePass

# Keystone definitions
KEYSTONE_REGION=RegionOne
export SERVICE_TOKEN="ADMIN_TOKEN"
export SERVICE_ENDPOINT="http://${HOST_IP}:35357/v2.0"

while getopts "u:D:p:m:K:R:E:T:vh" opt; do
  case $opt in
    u)
      MYSQL_USER=$OPTARG
      ;;
    D)
      MYSQL_DATABASE=$OPTARG
      ;;
    p)
      MYSQL_PASSWORD=$OPTARG
      ;;
    m)
      MYSQL_HOST=$OPTARG
      ;;
    K)
      MASTER=$OPTARG
      ;;
    R)
      KEYSTONE_REGION=$OPTARG
      ;;
    E)
      export SERVICE_ENDPOINT=$OPTARG
      ;;
    T)
      export SERVICE_TOKEN=$OPTARG
      ;;
    v)
      set -x
      ;;
    h)
      cat <<EOF
Usage: $0 [-m mysql_hostname] [-u mysql_username] [-D mysql_database] [-p mysql_password]
       [-K keystone_master ] [ -R keystone_region ] [ -E keystone_endpoint_url ]
       [ -T keystone_token ]

Add -v for verbose mode, -h to display this message.
EOF
      exit 0
      ;;
    \?)
      echo "Unknown option -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument" >&2
      exit 1
      ;;
  esac
done

if [ -z "$KEYSTONE_REGION" ]; then
  echo "Keystone region not set. Please set with -R option or set KEYSTONE_REGION variable." >&2
  missing_args="true"
fi

if [ -z "$SERVICE_TOKEN" ]; then
  echo "Keystone service token not set. Please set with -T option or set SERVICE_TOKEN variable." >&2
  missing_args="true"
fi

if [ -z "$SERVICE_ENDPOINT" ]; then
  echo "Keystone service endpoint not set. Please set with -E option or set SERVICE_ENDPOINT variable." >&2
  missing_args="true"
fi

if [ -z "$MYSQL_PASSWORD" ]; then
  echo "MySQL password not set. Please set with -p option or set MYSQL_PASSWORD variable." >&2
  missing_args="true"
fi

if [ -n "$missing_args" ]; then
  exit 1
fi

keystone service-create --name keystone --type identity --description "OpenStack Identity"
keystone service-create --name glance --type image --description "OpenStack Image Service"
keystone service-create --name nova --type compute --description "OpenStack Compute"
keystone service-create --name neutron --type network --description "OpenStack Networking"
keystone service-create --name cinder --type volume --description "OpenStack Block Storage"
keystone service-create --name cinderv2 --type volumev2 --description "OpenStack Block Storage v2"
keystone service-create --name swift --type object-store --description "OpenStack Storage Service"
keystone service-create --name heat --type orchestration --description "Orchestration"
keystone service-create --name heat-cfn --type cloudformation --description "Orchestration - CloudFormation"
keystone service-create --name ceilometer --type metering --description 'OpenStack Metering Service'
keystone service-create --name trove --type database --description "OpenStack Database Service"
keystone service-create --name ec2 --type ec2 --description 'OpenStack EC2 Service'

create_endpoint () {
  case $1 in
    identity)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':5000/v2.0' --adminurl 'http://'"$HOST_IP"':35357/v2.0' --internalurl 'http://'"$HOST_IP"':5000/v2.0'
    ;;
    image)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':9292' --adminurl 'http://'"$HOST_IP"':9292' --internalurl 'http://'"$HOST_IP"':9292'
    ;;
    compute)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':8774/v2/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8774/v2/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8774/v2/$(tenant_id)s'
    ;;
    network)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':9696' --adminurl 'http://'"$HOST_IP"':9696' --internalurl 'http://'"$HOST_IP"':9696'
    ;;
    volume)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':8776/v1/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8776/v1/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8776/v1/$(tenant_id)s'
    ;;
    volumev2)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':8776/v2/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8776/v2/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8776/v2/$(tenant_id)s'
    ;;
    object-store)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':8080/v1/AUTH_$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8080/v1' --internalurl 'http://'"$HOST_IP"':8080/v1/AUTH_$(tenant_id)s'
    ;;
    orchestration)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':8004/v1/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8004/v1/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8004/v1/$(tenant_id)s'
    ;;
    cloudformation)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':8000/v1' --adminurl 'http://'"$HOST_IP"':8000/v1' --internalurl 'http://'"$HOST_IP"':8000/v1'
    ;;
    metering)
    keystone endpoint-create --region $KEYSTONE_REGION --service_id $2 --publicurl 'http://'"$EXT_HOST_IP"':8777' --adminurl 'http://'"$HOST_IP"':8777' --internalurl 'http://'"$HOST_IP"':8777'
    ;;
    database)
    keystone endpoint-create --region $KEYSTONE_REGION --service_id $2 --publicurl 'http://'"$EXT_HOST_IP"':8779/v1.0/$(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8779/v1.0/$(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8779/v1.0/$(tenant_id)s'
    ;;
    ec2)
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $2 --publicurl 'http://'"$EXT_HOST_IP"':8773/services/Cloud' --adminurl 'http://'"$HOST_IP"':8773/services/Admin' --internalurl 'http://'"$HOST_IP"':8773/services/Cloud'
  esac
}

for i in identity image compute network volume volumev2 object-store object-store orchestration cloudformation metering database ec2; do
  id=`mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -ss -e "SELECT id FROM service WHERE type='"$i"';"` || exit 1
  create_endpoint $i $id
done
