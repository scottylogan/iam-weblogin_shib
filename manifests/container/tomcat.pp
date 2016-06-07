# Installs Tomcat 7.x Container for Shibboleth IdP

class shibboleth_idp::container::tomcat {

  class { 'tomcat':
    install_from_source => false,
    user                => 'idp',
    group               => 'idp',
    manage_user         => false,
    manage_group        => false,
    purge_connectors    => true,
    purge_realms        => true,
    catalina_home       => '/usr/share/tomcat7',
  }

  tomcat::instance{ 'idp':
    package_name => 'tomcat7',
    catalina_base => '/var/lib/tomcat7',
  }
  ->
  tomcat::config::server { 'idp':
    catalina_base => '/var/lib/tomcat7',
    port          => '8005',
  }
  ->
  tomcat::config::server::connector { 'idp-ajp':
    catalina_base => '/var/lib/tomcat7',
    port                  => '8009',
    protocol              => 'AJP/1.3',
    additional_attributes => {
      'redirectPort' => '443'
    },
    connector_ensure => 'present',
  }
  ->


  tomcat::config::server { 'idp':
    
    
  }



  if 
  tomcat::service { 'default':
    use_jsvc     => false,
    use_init     => true,
    service_name => 'tomcat',
  }

  file {
    [
      '/var/log/tomcat7',
    ]:

    ensure  => directory,
    owner   => 'idp',
    group   => 'idp',
    mode    => '0755',
  }
}

