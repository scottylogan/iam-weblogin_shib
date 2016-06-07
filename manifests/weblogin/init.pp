class idp3::weblogin (
  $template_base = '/usr/share/weblogin',
  $template_name = 'itlab',
  $idp_version = '3.2.1',
  $idp_dir = '/opt/shibboleth-idp',
  $tomcat_user = 'tomcat7',
  $tomcat_conf = '/etc/tomcat7',
  $tomcat_pkg  = 'tomcat7',
) {

  package {
    [
      'webauth-weblogin',
      'libapache2-mod-webkdc',
      # not declared as a dependency by the weblogin packages
      # but needed (maybe only when WebKdcDebug is enabled?)
      'libtime-duration-perl',
    ]:
    ensure => latest,
    notify => [
      File[$template_base],
      File['/etc/webkdc'],
    ],
  }

  file {
    [
      $template_base,
      '/etc/webkdc',
    ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${template_base}/${template_name}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => 'u+rwX,ga+rX',
    recurse => true,
    source  => "puppet:///modules/${module_name}/weblogin/${template_name}",
  }

  file { '/etc/webkdc/token.acl':
    ensure  => file,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => template("${module_name}/token.acl.erb"),
    require => Package['libapache2-mod-webkdc'],
  }

  file { '/etc/webkdc/webkdc.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => template("${module_name}/webkdc.conf.erb"),
    require => Package['libapache2-mod-webkdc'],
  }

  file { '/etc/apache2/sites-available/weblogin.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0644',
    content => template("${module_name}/apache2/weblogin.conf.erb"),
    require => Package['apache2'],
    notify  => Exec['enable site'],
  }

  file { '/etc/apache2/sites-available/weblogin-ssl.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0644',
    content => template("${module_name}/apache2/weblogin-ssl.conf.erb"),
    require => Package['apache2'],
    notify  => Exec['enable ssl site'],
  }

  exec { 'enable site':
    command => '/usr/sbin/a2ensite weblogin.conf',
    creates => '/etc/apache2/sites-enabled/weblogin.conf',
    notify  => Exec['restart apache'],
  }

  exec { 'enable ssl site':
    command => '/usr/sbin/a2ensite weblogin-ssl.conf',
    creates => '/etc/apache2/sites-enabled/weblogin-ssl.conf',
    notify  => Exec['restart apache'],
  }

  exec { 'enable mod_webkdc':
    command => '/usr/sbin/a2enmod webkdc',
    creates => '/etc/apache2/mods-enabled/webkdc.load',
    require => Package['libapache2-mod-webkdc'],
    notify  => Exec['restart apache'],
  }
}    
