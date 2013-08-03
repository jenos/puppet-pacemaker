# == Class: pacemaker
#
# See README.md
#
# === Authors
#
# - Vaidas Jablonskis <jablonskis@gmail.com>
#
class pacemaker(
  $service       = 'running',
  $onboot        = true,
  $package       = 'installed',
  $bindnetaddr   = undef,
  $mcastaddr     = undef,
  $mcastport     = 5410,
  $debug_logging = 'off',
  $crm_config    = undef,
  $nodes         = undef,
  $resources     = undef,
  $constraints   = undef,
) {
  case $::osfamily {
    Debian: {
      # do nothing - supported distro
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }


  $package_name           = 'corosync'
  $pacemaker_package_name = 'pacemaker'
  $service_name           = 'corosync'

  $pcmk_service_file      = '/etc/corosync/service.d/pacemaker'
  $pcmk_service_template  = 'pacemaker.erb'

  $config_file            = '/etc/corosync/corosync.conf'
  $conf_template          = 'corosync.conf.erb'

  $cib_xml_file           = '/etc/corosync/cib_config.xml'
  $cib_xml_template       = 'cib_config.xml.erb'

  $default_file           = '/etc/default/corosync'
  $default_file_template  = 'corosync.default.erb'


  if $bindnetaddr == undef {
    fail('Please specify bindnetaddr.')
  }

  if $mcastaddr == undef {
    fail('Please specify mcastaddr.')
  }

  if $nodes == undef {
    fail('Please specify at least one node of your cluster.')
  }

  package { $package_name:
    ensure  => $package,
  }

  package { $pacemaker_package_name:
    ensure  => installed,
  }

  service { $service_name:
    ensure     => $service,
    enable     => $onboot,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                    File[$config_file],
                    File[$default_file],
                    Package[$package_name]
                  ],
  }

  file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/${conf_template}"),
    notify  => Service[$service_name],
    require => Package[$package_name],
  }

  file { $pcmk_service_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/${pcmk_service_template}"),
    notify  => Service[$service_name],
    require => Package[$package_name],
  }

  if $::osfamily == 'Debian' {
    file { $default_file:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/${default_file_template}"),
      require => Package[$package_name],
    }
  }

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
    command     => "cibadmin --replace --scope configuration --xml-file ${cib_xml_file}",
    refreshonly => true,
  }
}
