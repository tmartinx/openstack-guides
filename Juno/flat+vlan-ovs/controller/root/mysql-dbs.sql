DROP DATABASE IF EXISTS keystone;
CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystoneUser'@'%' IDENTIFIED BY 'keystonePass';

DROP DATABASE IF EXISTS glance;
CREATE DATABASE glance;
GRANT ALL ON glance.* TO 'glanceUser'@'%' IDENTIFIED BY 'glancePass';

DROP DATABASE IF EXISTS nova;
CREATE DATABASE nova;
GRANT ALL ON nova.* TO 'novaUser'@'%' IDENTIFIED BY 'novaPass';

DROP DATABASE IF EXISTS cinder;
CREATE DATABASE cinder;
GRANT ALL ON cinder.* TO 'cinderUser'@'%' IDENTIFIED BY 'cinderPass';

DROP DATABASE IF EXISTS neutron;
CREATE DATABASE neutron;
GRANT ALL ON neutron.* TO 'neutronUser'@'%' IDENTIFIED BY 'neutronPass';

DROP DATABASE IF EXISTS heat;
CREATE DATABASE heat;
GRANT ALL ON heat.* TO 'heatUser'@'%' IDENTIFIED BY 'heatPass'; 

DROP DATABASE IF EXISTS trove;
CREATE DATABASE trove;
GRANT ALL ON trove.* TO 'troveUser'@'%' IDENTIFIED BY 'trovePass'; 
