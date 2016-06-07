# install Apache 2.4 for Shibboleth IdP

class shibboleth_idp::webserver::apache_proxy {

  if $shibboleth_idp::containerized {
    $logroot          = '/dev'
    $access_log_file  = 'stdout'
    $error_log_file   = 'stdout'
  }
  else {
    $logroot          = '/var/log/apache2'
    $access_log_file  = 'access_log'
    $error_log_file   = 'error_log'
    file {
      [
        '/var/log/apache2',
        '/var/lock/apache2',
        '/var/run/apache2',
      ]:

      ensure  => directory,
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0755',
      require => Package['httpd'],
    }
  }

  if $shibboleth_idp::env_hostname {
    $hostname = "\${${shibboleth_idp::env_hostname}}"
  }
  else {
    $hostname = $shibboleth_idp::hostname
  }

  class { 'apache':
    service_enable      => $shibboleth_idp::service_enable,
    servername          => $hostname,
    default_mods        => false,
    default_confd_files => false,
    default_vhost       => false,
    log_formats         => {
      vhost_common => '%v %h %l %u %t \"%r\" %>s %b',
      combined_elb => '%v:%p %{X-Forwarded-For}i %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"',
    },
    logroot             => $logroot,
    mpm_module          => 'prefork',
  }

  apache::mod {
    [
      'env',
      'rewrite',
      'authn_core',
      'access_compat',
      'proxy',
      'proxy_ajp',
      'expires',
      'headers',
    ]:
  }

  apache::vhost { 'redirect':
    port                => $shibboleth_idp::http_port,
    docroot             => '/var/www',
    docroot_owner       => 'root',
    docroot_group       => 'www-data',
    docroot_mode        => '0755',
    default_vhost       => true,
    serveradmin         => $shibboleth_idp::support_email,
    servername          => $hostname,
    access_log_format   => 'combined_elb',
    access_log_file     => $access_log_file,
    error_log_file      => $error_log_file,
    redirect_source     => '/',
    redirect_dest       => "https://${hostname}/",
    redirect_status     => 'permanent',
  }

  class { 'apache::mod::ssl':
    ssl_compression         => false,
    ssl_cryptodevice        => 'builtin',
    ssl_options             => [ 'StdEnvVars' ],
    ssl_openssl_conf_cmd    => undef,
    ssl_cipher              => 'HIGH:MEDIUM:!aNULL:!kRSA:!MD5:!RC4',
    ssl_honorcipherorder    => 'On',
    ssl_protocol            => [ 'all', '-SSLv2', '-SSLv3' ],
    ssl_pass_phrase_dialog  => 'builtin',
    ssl_random_seed_bytes   => '512',
    ssl_sessioncachetimeout => '300',
  }

  apache::vhost { 'idp':
    priority            => '25',
    port                => $shibboleth_idp::https_port,
    docroot             => '/var/www',
    docroot_owner       => 'root',
    docroot_group       => 'www-data',
    docroot_mode        => '0755',
    ssl                 => true,
    serveradmin         => $shibboleth_idp::support_email,
    servername          => $hostname,
    access_log_format   => 'combined_elb',
    access_log_file     => $access_log_file,
    error_log_file      => $error_log_file,
    ssl_cert            => '/etc/ssl/certs/server.pem',
    ssl_key             => '/etc/ssl/private/server.key',
    ssl_chain           => '/etc/ssl/certs/server-chain.pem',
  }

  # not using proxy_pass, because we don't need
  # the <Location /idp> block, nor ProxPassReverse
  concat::fragment { 'idp-custom-fragment':
    target  => '25-idp.conf',
    order   => 100,
    content => "\n  ProxyPass /idp ajp://localhost:8009/idp retry=5\n  <Proxy ajp://localhost:8009>\n    Require all granted\n  </Proxy>\n\n",
  }

}