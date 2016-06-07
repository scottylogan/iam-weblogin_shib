# Class: shibboleth_idp::params
#
# This class configures parameters for the shibboleth_idp module.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class shibboleth_idp::params {
  $idp_war_base_url = 'https://shibboleth.net/downloads/identity-provider/latest',
  $idp_war_name     = 'shibboleth-identity-provider',
  $idp_war_suffix   = 'tar.gz',
  $idp_war_version  = '3.2.1',
  $idp_war_hashtype = 'sha256',
  $idp_war_url      = "${idp_war_base_url}/${idp_war_name}-${idp_war_version}.${idp_war_suffix}",
  $idp_war_hash_url = "${idp_war_url}.${idp_war_hashtype}",
  $jdk              = 'openjdk',
  $jdk_version      = '7',
  $java_container   = 'tomcat',
  $java_cont_vers   = '7',
  $web_server       = 'apache',
  $ssl_offload      = false,
  $containerized    = false,
  $support_email    = undef,
  $http_port        = 80,
  $https_port       = 443,
  $hostname         = undef,
  $env_hostname     = undef,
}