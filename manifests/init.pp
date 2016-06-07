class idp3 (
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
      'heimdal-clients',
      'apache2-mpm-prefork',
      'apache2',
      'apache2-bin',
      'openjdk-7-jre-headless',
      $tomcat_pkg,

      # sasl gssapi for LDAP connection
      'libsasl2-modules-gssapi-heimdal',
      # ldapsearch for debugging LDAP issues
      'ldap-utils',
      # 
      'libmysql-java',
      # not needed - using tomcat-jdbc.jar
      #'libcommons-dbcp-java',
    ]:
    ensure => latest,
    notify => [
      File[$template_base],
      File['/etc/webkdc'],
    ],
  }

  exec { 'enable mod_ssl':
    command => '/usr/sbin/a2enmod ssl',
    creates => '/etc/apache2/mods-enabled/ssl.load',
    require => Package['apache2-bin'],
    notify  => Exec['restart apache'],
  }

  exec { 'enable mod_proxy_ajp':
    command => '/usr/sbin/a2enmod proxy proxy_ajp',
    creates => '/etc/apache2/mods-enabled/proxy_jap.load',
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

  exec { '/tmp/idp.tar.gz':
    command => "/usr/bin/curl -o /tmp/idp.tar.gz https://shibboleth.net/downloads/identity-provider/${idp_version}/shibboleth-identity-provider-${idp_version}.tar.gz",
    creates => '/tmp/idp.tar.gz',
  }

  file { '/tmp/dist':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  exec { 'unpack idp.tar.gz':
    command => '/bin/tar xzf /tmp/idp.tar.gz',
    cwd     => '/tmp/dist',
    creates => "/tmp/dist/shibboleth-identity-provider-${idp_version}/bin/install.sh",
    require => [
      Exec['/tmp/idp.tar.gz'],
      File['/tmp/dist'],
    ],
  }

  file { '/tmp/idp-install.properties':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template("${module_name}/idp-install.properties.erb"),
  }

  exec { 'install IdP':
    command     => "/tmp/dist/shibboleth-identity-provider-${idp_version}/bin/install.sh -Didp.relying.party.present= -Didp.src.dir=. -Didp.target.dir=${idp_dir} -Didp.merge.properties=/tmp/idp-install.properties -Didp.sealer.password=secret -Didp.keystore.password=secret -Didp.conf.filemode=644 -Didp.host.name=${fqdn} -Didp.scope=${domain}",
    cwd         => '/tmp/dist',
    environment => [ 'JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64' ],
    require     => [
      Exec['unpack idp.tar.gz'],
      Package['openjdk-7-jre-headless'],
      File['/tmp/idp-install.properties'],
    ],
  }

  exec { 'install self-signed cert':
    command     => "${idp_dir}/bin/keygen.sh --lifetime 3 --certfile ${idp_dir}/credentials/idp.crt --keyfile ${idp_dir}/credentials/idp.key --hostname ${fqdn} --uriAltName https://${fqdn}/idp/shibboleth",
    cwd         => $idp_dir,
    environment => [ 'JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64' ],
    require     => Exec['install IdP'],
  }

  file { "${idp_dir}/credentials.properties":
    ensure => file,
    owner  => 'root',
    group  => $tomcat_user,
    mode   => '0640',
    content => 'idp.sealer.password = secret',
    require => Exec['install IdP'],
  }

  exec { 'fix group ownership':
    command => "/bin/chgrp ${tomcat_user} ${idp_dir}/credentials/*",
    require => Exec['install IdP'],
  }

  exec { 'fix permissions':
    command => "/bin/chmod 440 ${idp_dir}/credentials/*",
    require => Exec['install IdP'],
  }

  file { "${tomcat_conf}/server.xml":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/${module_name}/tomcat/server.xml",
    require => Package[$tomcat_pkg],
  }

  file { "${tomcat_conf}/Catalina/localhost/idp.xml":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/${module_name}/tomcat/idp.xml",
    require => Package[$tomcat_pkg],
  }
}

