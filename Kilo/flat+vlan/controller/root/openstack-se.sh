#! /bin/sh
#
# OpenStack Services and Endpoints
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
# http://docs.openstack.org/kilo/install-guide/install/apt/content/keystone-services.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/keystone-users.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/glance-install.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/ch_nova.html#nova-controller-install
# http://docs.openstack.org/kilo/install-guide/install/apt/content/neutron-controller-node.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/cinder-install-controller-node.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/swift-install-controller-node.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/heat-install-controller-node.html
# http://docs.openstack.org/kilo/install-guide/install/apt/content/ceilometer-controller-install.html

# Host IP address, hostname or FQDN - Can resolve to a IPv6 address too
HOST_IP=controller.yourdomain.com
EXT_HOST_IP=controller.yourdomain.com

# Keystone definitions
REGION=RegionOne
export OS_TOKEN="ADMIN_TOKEN"
export OS_URL="http://${HOST_IP}:35357/v2.0"

while getopts "K:R:E:T:vh" opt; do
  case $opt in
    K)
      MASTER=$OPTARG
      ;;
    R)
      REGION=$OPTARG
      ;;
    E)
      export OS_URL=$OPTARG
      ;;
    T)
      export OS_TOKEN=$OPTARG
      ;;
    v)
      set -x
      ;;
    h)
      cat <<EOF
Usage: $0 [-K keystone_master ] [ -R keystone_region ] [ -E keystone_endpoint_url ]
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

if [ -z "$REGION" ]; then
  echo "Keystone region not set. Please set with -R option or set REGION variable." >&2
  missing_args="true"
fi

if [ -z "$OS_TOKEN" ]; then
  echo "Keystone service token not set. Please set with -T option or set OS_TOKEN variable." >&2
  missing_args="true"
fi

if [ -z "$OS_URL" ]; then
  echo "Keystone service endpoint not set. Please set with -E option or set OS_URL variable." >&2
  missing_args="true"
fi

if [ -n "$missing_args" ]; then
  exit 1
fi

openstack service create --name keystone --description "OpenStack Identity" identity
openstack service create --name glance --description "OpenStack Image service" image
openstack service create --name nova --description "OpenStack Compute" compute
openstack service create --name novav3 --description "OpenStack Compute V3" computev3
openstack service create --name neutron --description "OpenStack Networking" network
openstack service create --name cinder --description "OpenStack Block Storage" volume
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name heat --description "Orchestration" orchestration
openstack service create --name heat-cfn --description "Orchestration"  cloudformation
openstack service create --name ec2 --description="EC2 Compatibility Layer" ec2
openstack service create --name swift --description="Swift Service" object-store
openstack service create --name ceilometer --description "OpenStack Metering Service" metering

openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':5000/v2.0' --internalurl 'http://'"$HOST_IP"':5000/v2.0' --adminurl 'http://'"$HOST_IP"':35357/v2.0' identity
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':9292' --internalurl 'http://'"$HOST_IP"':9292' --adminurl 'http://'"$HOST_IP"':9292' image
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8774/v2/%(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8774/v2/%(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8774/v2/%(tenant_id)s' compute
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8774/v3' --internalurl 'http://'"$HOST_IP"':8774/v3' --adminurl 'http://'"$HOST_IP"':8774/v3' computev3
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':9696' --internalurl 'http://'"$HOST_IP"':9696' --adminurl 'http://'"$HOST_IP"':9696' network
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8776/v2/%(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8776/v2/%(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8776/v2/%(tenant_id)s' volume
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8776/v2/%(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8776/v2/%(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8776/v2/%(tenant_id)s' volumev2
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8004/v1/%(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8004/v1/%(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8004/v1/%(tenant_id)s' orchestration
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8000/v1' --internalurl 'http://'"$HOST_IP"':8000/v1' --adminurl 'http://'"$HOST_IP"':8000/v1' cloudformation
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8773/services/Cloud' --internalurl 'http://'"$HOST_IP"':8773/services/Cloud' --adminurl 'http://'"$HOST_IP"':8773/services/Admin' ec2
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8080/v1/AUTH_%(tenant_id)s' --internalurl 'http://'"$HOST_IP"':8080/v1/AUTH_%(tenant_id)s' --adminurl 'http://'"$HOST_IP"':8080/v1' swift
openstack endpoint create --region $REGION --publicurl 'http://'"$EXT_HOST_IP"':8777' --internalurl 'http://'"$HOST_IP"':8777' --adminurl 'http://'"$HOST_IP"':8777' metering
