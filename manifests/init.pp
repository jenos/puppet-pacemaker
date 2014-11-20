# == Class: pacemaker
#
# See README.md
#
# === Authors
#
# - Vaidas Jablonskis <jablonskis@gmail.com>
#
class pacemaker(
  $bindnetaddr,
  $mcastaddr,
  $nodes,
  $mcastport             = 5410,
  $crm_config            = undef,
  $resources             = undef,
  $constraints           = undef,
  $packages              = $::pacemaker::params::packages,
  $package_require       = $::pacemaker::params::package_require,
  $service_name          = $::pacemaker::params::service_name,
  $pcmk_service_file     = $::pacemaker::params::pcmk_service_file,
  $pcmk_service_template = $::pacemaker::params::pcmk_service_template,
  $config_file           = $::pacemaker::params::config_file,
  $conf_template         = $::pacemaker::params::conf_template,
  $cib_xml_file          = $::pacemaker::params::cib_xml_file,
  $cib_xml_template      = $::pacemaker::params::cib_xml_template,
  $service               = $::pacemaker::params::service,
  $enabled               = $::pacemaker::params::enabled,
  $manage_cib            = $::pacemaker::params::manage_cib,
  $debug_logging         = $::pacemaker::params::debug_logging
) inherits ::pacemaker::params {

  package { $packages: }

  service { $service_name:
    ensure     => $::pacemaker::params::service,
    enable     => $enabled,
    hasrestart => true,
    hasstatus  => true,
    require    => [ File[$config_file], File[$pcmk_service_file], Package['openais'] ],
  }

  file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/${conf_template}"),
    notify  => Service[$service_name],
    require => Package['corosync'],
  }

  file { $pcmk_service_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/${pcmk_service_template}"),
    notify  => Service[$service_name],
    require => Package['pacemaker'],
  }

  if $manage_cib {
    file { $cib_xml_file:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/${cib_xml_template}"),
      notify  => Exec['crm_verify_cib_xml_file'],
      require => Service[$service_name],
    }

    exec { 'crm_verify_cib_xml_file':
      path        => '/bin:/usr/sbin:/usr/bin',
      command     => "crm_verify --xml-file ${cib_xml_file}",
      refreshonly => true,
      notify      => Exec['cibadmin_apply_cib_xml_file'],
    }

    exec { 'cibadmin_apply_cib_xml_file':
      path        => '/bin:/usr/sbin:/usr/bin',
      command     => "crm_attribute --type crm_config --query --name \
                      dc-version || sleep 10s && cibadmin --replace \
                      --scope configuration --xml-file ${cib_xml_file}",
      refreshonly => true,
    }
  }
}
