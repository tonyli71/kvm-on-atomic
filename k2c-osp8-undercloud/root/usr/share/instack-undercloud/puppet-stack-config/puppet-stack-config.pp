# Copyright 2015 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

$enabled  = true
$cluster  = true
$bootstrap = true
$wsrep_cluster_members  = [hiera('controller_host')]
$wsrep_sst_username     = 'wsrep_sst'
$wsrep_sst_password     = 'wspass'
$controller_virtual_ip = hiera('controller_host')
$control_virtual_interface = 'br-ctlplane'

if count(hiera('ntp::servers')) > 0 {
  include ::ntp
}

include ::rabbitmq

# Tony Li modify for HA base on Galara
# Install and configure MySQL Server
if $cluster {
    package { "mariadb-server":
            ensure => "absent",
            name     => 'mariadb-server',
            provider => 'yum',
            notify   => Class['mysql::server'],
    }
    package { 'galera':
            ensure   => 'installed',
            notify   => Class['mysql::server'],
    }
   service { 'galera':
      ensure => true,
      name   => 'garbd',
      enable => true,
   }
   #class { 'galera::server':
   #        create_mysql_resource => false,
   #        wsrep_bind_address => hiera('controller_host'),
   #        wsrep_cluster_name   => 'galera_cluster',
   #        wsrep_sst_method     => 'rsync',
   #        wsrep_sst_username   => $wsrep_sst_username,
   #        wsrep_sst_password   => $wsrep_sst_password,
   #        wsrep_cluster_members => $wsrep_cluster_members,
   #        bootstrap  => $bootstrap,
   #}
   class { '::mysql::server':
     package_name => 'mariadb-galera-server',
     override_options => {
       'mysqld' => {
         'bind-address' => hiera('controller_host'),
         'max_connections' => hiera('mysql_max_connections'),
         'open_files_limit' => '-1',
         'innodb_file_per_table' => 'ON',
       }
     },
     restart          => true
   }
} else {
  # TODO Galara
  class { '::mysql::server':
     override_options => {
       'mysqld' => {
         'bind-address'          => hiera('controller_host'),
         'max_connections'       => hiera('mysql_max_connections'),
         'open_files_limit'      => '-1',
         'innodb_file_per_table' => 'ON',
      },
     },
    restart          => true
  }
}

# Raise the mysql file limit
exec { 'systemctl-daemon-reload':
  command => '/bin/systemctl daemon-reload'
}
file { '/etc/systemd/system/mariadb.service.d':
  ensure => 'directory',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}
file { '/etc/systemd/system/mariadb.service.d/limits.conf':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => "[Service]\nLimitNOFILE=16384\n",
  require => File['/etc/systemd/system/mariadb.service.d'],
  notify  => [Exec['systemctl-daemon-reload'], Service['mysqld']],
}
Exec['systemctl-daemon-reload'] -> Service['mysqld']

# FIXME: this should only occur on the bootstrap host (ditto for db syncs)
# Create all the database schemas
# Example DSN format: mysql+pymysql://user:password@host/dbname
$allowed_hosts = ['%',hiera('controller_host')]
$keystone_dsn = split(hiera('keystone::database_connection'), '[@:/?]')
class { '::keystone::db::mysql':
  user          => $keystone_dsn[3],
  password      => $keystone_dsn[4],
  host          => $keystone_dsn[5],
  dbname        => $keystone_dsn[6],
  allowed_hosts => $allowed_hosts,
}
$glance_dsn = split(hiera('glance::api::database_connection'), '[@:/?]')
class { '::glance::db::mysql':
  user          => $glance_dsn[3],
  password      => $glance_dsn[4],
  host          => $glance_dsn[5],
  dbname        => $glance_dsn[6],
  allowed_hosts => $allowed_hosts,
}
$nova_dsn = split(hiera('nova::database_connection'), '[@:/?]')
class { '::nova::db::mysql':
  user          => $nova_dsn[3],
  password      => $nova_dsn[4],
  host          => $nova_dsn[5],
  dbname        => $nova_dsn[6],
  allowed_hosts => $allowed_hosts,
}
$neutron_dsn = split(hiera('neutron::server::database_connection'), '[@:/?]')
class { '::neutron::db::mysql':
  user          => $neutron_dsn[3],
  password      => $neutron_dsn[4],
  host          => $neutron_dsn[5],
  dbname        => $neutron_dsn[6],
  allowed_hosts => $allowed_hosts,
}
$heat_dsn = split(hiera('heat_dsn'), '[@:/?]')
class { '::heat::db::mysql':
  user          => $heat_dsn[3],
  password      => $heat_dsn[4],
  host          => $heat_dsn[5],
  dbname        => $heat_dsn[6],
  allowed_hosts => $allowed_hosts,
}
$ceilometer_dsn = split(hiera('ceilometer::db::database_connection'), '[@:/?]')
class { '::ceilometer::db::mysql':
  user          => $ceilometer_dsn[3],
  password      => $ceilometer_dsn[4],
  host          => $ceilometer_dsn[5],
  dbname        => $ceilometer_dsn[6],
  allowed_hosts => $allowed_hosts,
}
$ironic_dsn = split(hiera('ironic::database_connection'), '[@:/?]')
class { '::ironic::db::mysql':
user          => $ironic_dsn[3],
password      => $ironic_dsn[4],
host          => $ironic_dsn[5],
dbname        => $ironic_dsn[6],
allowed_hosts => $allowed_hosts,
}

# pre-install swift here so we can build rings
include ::swift

if hiera('service_certificate', undef) {
  $keystone_public_endpoint = join(['https://', hiera('controller_public_vip'), ':13000'])
} else {
  $keystone_public_endpoint = undef
}

class { '::keystone':
  debug            => hiera('debug'),
  public_bind_host => hiera('controller_host'),
  admin_bind_host  => hiera('controller_host'),
  public_endpoint  => $keystone_public_endpoint,
  service_name     => 'httpd',
}
include ::keystone::wsgi::apache

include ::keystone::roles::admin
include ::keystone::endpoint

include ::heat::keystone::auth
include ::neutron::keystone::auth
include ::glance::keystone::auth
include ::nova::keystone::auth
include ::ceilometer::keystone::auth
include ::swift::keystone::auth
include ::ironic::keystone::auth

# Because os-cloud-config/tree/os_cloud_config/keystone.py already managed
# it but with a different service name than Puppet will do (novav3), we want Puppet
# to making sure computev3 is not here anymore and we will add novav3 later.
keystone_service { 'nova::computev3': ensure => absent }
Keystone_service<||> -> Keystone_endpoint<||>

#TODO: need a cleanup-keystone-tokens.sh solution here
keystone_config {
  'ec2/driver': value => 'keystone.contrib.ec2.backends.sql.Ec2';
}
file { [ '/etc/keystone/ssl', '/etc/keystone/ssl/certs', '/etc/keystone/ssl/private' ]:
  ensure  => 'directory',
  owner   => 'keystone',
  group   => 'keystone',
  require => Package['keystone'],
}
file { '/etc/keystone/ssl/certs/signing_cert.pem':
  content => hiera('keystone_signing_certificate'),
  owner   => 'keystone',
  group   => 'keystone',
  notify  => Service['httpd'],
  require => File['/etc/keystone/ssl/certs'],
}
file { '/etc/keystone/ssl/private/signing_key.pem':
  content => hiera('keystone_signing_key'),
  owner   => 'keystone',
  group   => 'keystone',
  notify  => Service['httpd'],
  require => File['/etc/keystone/ssl/private'],
}
file { '/etc/keystone/ssl/certs/ca.pem':
  content => hiera('keystone_ca_certificate'),
  owner   => 'keystone',
  group   => 'keystone',
  notify  => Service['httpd'],
  require => File['/etc/keystone/ssl/certs'],
}

# TODO: notifications, scrubber, etc.
class { '::glance::api':
  debug => hiera('debug'),
}
class { '::glance::registry':
  debug => hiera('debug'),
}
include ::glance::backend::file
include ::glance::notify::rabbitmq

class { '::nova':
  rabbit_hosts       => [hiera('controller_host')],
  glance_api_servers => join([hiera('glance_protocol'), '://', hiera('controller_host'), ':', hiera('glance_port')]),
  debug              => hiera('debug'),
}

include ::nova::api
include ::nova::cert
include ::nova::compute
include ::nova::conductor
include ::nova::scheduler

class {'::nova::scheduler::filter':
  ram_allocation_ratio => hiera('nova::scheduler::filter::ram_allocation_ratio'),
}

class { '::neutron':
  rabbit_hosts => [hiera('controller_host')],
  debug        => hiera('debug'),
}

include ::neutron::server
include ::neutron::server::notifications
include ::neutron::quota
include ::neutron::plugins::ml2

# NOTE(lucasagomes): This bit might be superseded by
# https://review.openstack.org/#/c/172040/
file { 'dnsmasq-ironic.conf':
  ensure  => present,
  path    => '/etc/dnsmasq-ironic.conf',
  owner   => 'ironic',
  group   => 'ironic',
  mode    => '0644',
  replace => false,
  content => 'dhcp-match=ipxe,175';
}

class { '::neutron::agents::dhcp':
  dnsmasq_config_file => '/etc/dnsmasq-ironic.conf',
}

class { '::neutron::agents::ml2::ovs':
  bridge_mappings => split(hiera('neutron_bridge_mappings'), ','),
}

neutron_config {
  'DEFAULT/notification_driver': value => 'messaging';
}

# swift proxy
include ::memcached
include ::swift::proxy
include ::swift::ringbuilder
include ::swift::proxy::proxy_logging
include ::swift::proxy::healthcheck
include ::swift::proxy::cache
include ::swift::proxy::keystone
include ::swift::proxy::authtoken
include ::swift::proxy::staticweb
include ::swift::proxy::ratelimit
include ::swift::proxy::catch_errors
include ::swift::proxy::tempauth
include ::swift::proxy::tempurl
include ::swift::proxy::formpost

# swift storage
class { '::swift::storage::all':
  mount_check => str2bool(hiera('swift_mount_check')),
}
if(!defined(File['/srv/node'])) {
  file { '/srv/node':
    ensure  => directory,
    owner   => 'swift',
    group   => 'swift',
    require => Package['openstack-swift'],
  }
}
$swift_components = ['account', 'container', 'object']
swift::storage::filter::recon { $swift_components : }
swift::storage::filter::healthcheck { $swift_components : }

$controller_host = hiera('controller_host')
ring_object_device { "${controller_host}:6000/1":
  zone   => 1,
  weight => 1,
}
ring_container_device { "${controller_host}:6001/1":
  zone   => 1,
  weight => 1,
}
ring_account_device { "${controller_host}:6002/1":
  zone   => 1,
  weight => 1,
}

# Ceilometer
include ::ceilometer
include ::ceilometer::api
include ::ceilometer::db
include ::ceilometer::agent::notification
include ::ceilometer::agent::central
include ::ceilometer::alarm::notifier
include ::ceilometer::alarm::evaluator
include ::ceilometer::expirer
include ::ceilometer::collector
class { '::ceilometer::agent::auth':
  auth_url => join(['http://', hiera('controller_host'), ':5000/v2.0']),
}

Cron <| title == 'ceilometer-expirer' |> { command =>
  "sleep $((\$(od -A n -t d -N 3 /dev/urandom) % 86400)) && ${::ceilometer::params::expirer_command}" }

# TODO: add support for setting these to puppet-ceilometer
ceilometer_config {
  'hardware/readonly_user_name': value => hiera('snmpd_readonly_user_name');
  'hardware/readonly_user_password': value => hiera('snmpd_readonly_user_password');
}

# Heat
class { '::heat':
  debug            => hiera('debug'),
  keystone_ec2_uri => join(['http://', hiera('controller_host'), ':5000/v2.0/ec2tokens']),
}
heat_config {
  'clients/endpoint_type': value => 'internal',
}
include ::heat::api
include ::heat::api_cfn
include ::heat::api_cloudwatch
include ::heat::engine
include ::heat::keystone::domain
include ::heat::cron::purge_deleted

# We're creating the admin role and heat domain user in puppet and need
# to make sure they are done in order.
include ::keystone::roles::admin
Service['httpd'] -> Class['::keystone::roles::admin'] -> Class['::heat::keystone::domain']

nova_config {
  'DEFAULT/my_ip':                     value => $ipaddress;
  'DEFAULT/linuxnet_interface_driver': value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
  'DEFAULT/rpc_response_timeout':      value => '600';
  'DEFAULT/sync_power_state_interval': value => hiera('nova_sync_power_state_interval');
}

include ::nova::compute::ironic

class { '::nova::network::neutron':
  neutron_admin_auth_url    => join(['http://', hiera('controller_host'), ':35357/v2.0']),
  neutron_url               => join(['http://', hiera('controller_host'), ':9696']),
  neutron_admin_password    => hiera('neutron::server::auth_password'),
  neutron_admin_tenant_name => hiera('neutron::server::auth_tenant'),
  neutron_region_name       => '',
}

class { '::ironic::conductor':
  force_power_state_during_sync => hiera('ironic::conductor::force_power_state_during_sync'),
}

# dependency of pxe_drac
package{'openwsman-python': }
# dependency of pxe_ilo
package{'python-proliantutils': }

class { '::ironic':
  enabled_drivers => ['pxe_ipmitool', 'pxe_ssh', 'pxe_drac', 'pxe_ilo', 'pxe_wol'],
  debug           => hiera('debug'),
}

class { '::ironic::api':
  host_ip => hiera('controller_host'),
}

class { '::ironic::drivers::ipmi':
  retry_timeout => 15,
}

ironic_config {
  'DEFAULT/my_ip':                value => hiera('controller_host');
  'DEFAULT/rpc_response_timeout': value => '600';
  'glance/host':                  value => hiera('glance::api::bind_host');
  'inspector/enabled':            value => true;
  'pxe/http_url':                 value => 'http://$my_ip:8088';
  'pxe/http_root':                value => '/httpboot';
  'conductor/clean_nodes':        value => hiera('ironic::conductor::clean_nodes');
}

if str2bool(hiera('ipxe_deploy', true)) {
  ironic_config {
    'pxe/pxe_config_template':      value => '$pybasedir/drivers/modules/ipxe_config.template';
    'pxe/pxe_bootfile_name':        value => 'undionly.kpxe';
    'pxe/ipxe_enabled':             value => true;
  }
} else {
  ironic_config {
    'pxe/pxe_config_template':      value => '$pybasedir/drivers/modules/pxe_config.template';
    'pxe/ipxe_enabled':             value => false;
  }
}

include ::ironic::inspector

if hiera('service_certificate', undef) {
  class { '::tripleo::loadbalancer':
    controller_virtual_ip     => hiera('controller_admin_vip'),
    controller_hosts          => [hiera('controller_host')],
    control_virtual_interface => 'br-ctlplane',
    public_virtual_ip         => hiera('controller_public_vip'),
    public_virtual_interface  => 'br-ctlplane',
    service_certificate       => hiera('service_certificate', undef),
    keystone_admin            => true,
    keystone_public           => true,
    neutron                   => true,
    glance_api                => true,
    glance_registry           => true,
    nova_osapi                => true,
    nova_metadata             => true,
    swift_proxy_server        => true,
    heat_api                  => true,
    ceilometer                => true,
    ironic                    => true,
    rabbitmq                  => true,
  }
}

if str2bool(hiera('enable_tempest', true)) {
  # tempest
  # TODO: when puppet-tempest supports install by package, do that instead
  package{'openstack-tempest': }
  # needed for /bin/subunit-2to1 (called by run_tempest.sh)
  package{'subunit-filters': }
}

# Ensure dm thin-pool is never activated. This avoids an issue
# where the instack host (in this case on a VM) was crashing due to
# activation of the docker thin-pool associated with the atomic host.
augeas { 'lvm.conf':
  require => Package['openstack-nova-compute'],
  context => '/files/etc/lvm/lvm.conf/activation/dict/',
  changes => 'set auto_activation_volume_list/list ""'
}

if str2bool(hiera('enable_docker_registry', true)) {
  package{'docker-registry': }
  augeas { 'docker-registry':
    context => '/files/etc/sysconfig/docker-registry',
    changes => 'set REGISTRY_PORT 8787',
    notify  => Service['docker-registry'],
  }
  service { 'docker-registry':
    ensure  => running,
    require => Package['docker-registry'],
  }
}
