# Public: Installs SimpleSAMLphp and other tools

class shibboleth_idp (
  $service_enable = true,
  $jdk            = 'openjdk',
  $java_container = 'tomcat',
  $web_server     = 'apache',
  $ssl_offload    = false,
  $containerized  = false,
  $support_email  = undef,
  $http_port      = 80,
  $https_port     = 443,
  $hostname       = undef,
  $env_hostname   = undef,
) {

  validate_bool($service_enable)
  validate_string($jdk)
  validate_string($java_container)
  validate_string($web_server)
  validate_bool($ssl_offload)
  validate_bool($containerized)
  validate_integer($http_port)
  validate_integer($https_port)
  validate_string($hostname)
  validate_string($env_hostname)

  if ! $support_email {
    fail('support_email must be set')
  }

  if (! $hostname) and (! $env_hostname) {
    fail('hostname or env_hostname must be set')
  }

  if ($hostname) and ($env_hostname) {
    fail('only one of hostname or env_hostname can be set')
  }

  group { 'idp':
    ensure => present
  }

  user { 'idp':
    ensure  => present,
    require => Group['idp']
  }

  package {
    [
      'authbind',
    ]:
    ensure => latest,
  }


  if $ssl_offload {
    $authbind_ports = [
      "/etc/authbind/byport/${http_port}",
    ]
  }
  else {
    $authbind_ports = [
      "/etc/authbind/byport/${http_port}",
      "/etc/authbind/byport/${https_port}",
    ]
  }

  file { $authbind_ports:
    ensure  => file,
    owner   => 'idp',
    group   => 'idp',
    mode    => '0700',
    require => [
      Package['authbind'],
      User['idp'],
      Group['idp'],
    ],
  }

  case $jdk {
    'openjdk': { include shibboleth_idp::jdk::openjdk }
    'oracle':  { include shibboleth_idp::jdk::oracle  }
    default:   { fail("${jdk} is not a valid jdk: use 'openjdk' or 'oracle'") }
  }

  case $java_container {
    'tomcat': { include shibboleth_idp::container::tomcat }
    'jetty':  { include shibboleth_idp::container::jetty  }
    default:  { fail("${java_container} is not a valid container: use 'jetty' or 'tomcat'") }
  }

  case $web_server {
    'apache': { include shibboleth_idp::webserver::apache_proxy }
    'nginx':  { include shibboleth_idp::webserver::nginx_proxy }
    default:  { fail("${web_server} is not a valid web server: use 'apache' or 'nginx'")}
  }

  if ($jdk == 'openjdk') and ($container == 'jetty') {
    warn('OpenJDK and Jetty is not a well tested combination')
  }
  elsif ($jdk == 'oracle') and ($container == 'tomcat') {
    warn('Oracle JDK and Tomcat is not a well tested combination')
  }

}
