
class pacemaker::params {
  $packages               = ['corosync', 'pacemaker']
  $package_require        = [ 'corosync', 'pacemaker', 'crmsh' ]
  $service_name           = 'corosync'

  $pcmk_service_file      = '/etc/corosync/service.d/pacemaker'
  $pcmk_service_template  = 'pacemaker.erb'

  $config_file            = '/etc/corosync/corosync.conf'
  $conf_template          = 'corosync.conf.erb'

  $cib_xml_file           = '/etc/corosync/cib_config.xml'
  $cib_xml_template       = 'cib_config.xml.erb'

  $service                = 'running'
  $enabled                = 'true'
  $manage_cib             = 'false'
  $debug_logging          = 'off'

}
