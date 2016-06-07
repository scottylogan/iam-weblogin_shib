# Installs Jetty 9.x Container for Shibboleth IdP

class shibboleth_idp::container::jetty {

  remote_file { '/opt/jetty.tar.gz':
    ensure        => present,
    source        => 'http://download.eclipse.org/jetty/9.3.3.v20150827/dist/jetty-distribution-9.3.3.v20150827.tar.gz',
    checksum      => '3b79af6796e758cf10328014a84dbec4',
    checksum_type => 'md5',
  }

  file {
    [
      '/opt/jetty',
    ]:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  exec { 'unpack jetty':
    path    => '/usr/bin:/bin:/usr/sbin:/sbin',
    cwd     => '/opt/jetty',
    command => 'tar --strip-components=1 -xzf ../jetty.tar.gz',
    require => [
      RemoteFile['/opt/jetty.tar.gz'],
      File['/opt/jetty'],
    ]
  }

  exec { 'cleanup jetty':
    path    => '/usr/bin:/bin:/usr/sbin:/sbin',
    cwd     => '/opt',
    command => 'rm -f jetty.tar.gz',
    require => [
      Exec['unpack jetty'],
    ]
  }

  file {
    [
      '/var/log/jetty',
    ]:
    ensure  => directory,
    owner   => 'idp',
    group   => 'idp',
    mode    => '0755',
  }
}
