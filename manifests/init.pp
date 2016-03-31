class weblogin (
  $template_base = '/usr/share/weblogin',
  $template_name = 'itlab',
  $domain = 'itlab.stanford.edu',
) {

  package {
    [
      'heimdal-clients',
      'apache2-mpm-prefork',
      'webauth-weblogin',
      'libapache2-mod-webkdc',
      'apache2',
      'apache2-bin',
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

  file { '/tmp/templates.tar':
    ensure => file,
    source => "puppet:///modules/${module_name}/templates.tar",
  }

  exec { 'unpack itlab template':
    command => "/bin/tar -C ${template_base} -xf /tmp/templates.tar",
    creates => "${template_base}/${template_name}",
    require => [
      File [$template_base],
      File ['/tmp/templates.tar'],
    ],
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

  exec { 'enable mod_ssl':
    command => '/usr/sbin/a2enmod ssl',
    creates => '/etc/apache2/mods-enabled/ssl.load',
    require => Package['apache2-bin'],
    notify  => Exec['restart apache'],
  }

  exec { 'restart apache':
    command     => '/usr/sbin/service apache2 restart',
    refreshonly => true,
  }

  file { '/etc/krb5.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/krb5.conf.erb"),
    require => Package['heimdal-clients'],
  }

}

