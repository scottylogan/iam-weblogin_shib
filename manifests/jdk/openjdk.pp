# Installs OpenJDK 7.x JDK for Shibboleth IdP

class shibboleth_idp::jdk::openjdk {

  package { 'openjdk-7-jre-headless':
    ensure => latest,
  }

}
