# Installs Oracle 8.x JDK for Shibboleth IdP

class shibboleth_idp::jdk::oracle {

  class { 'jdk_oracle':
    version       => '8',
    jce           => true,
    default_java  => true,
  }

}
