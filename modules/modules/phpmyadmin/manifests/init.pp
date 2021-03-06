# === Class phpmyadmin
#
# Documentation
#
# install phpmyadmin
#
class phpmyadmin {

      # variable hiera
      $phpmyadmin   = hiera_hash('phpmyadmin')
      $settings     = $phpmyadmin['settings']

      case $::osfamily {
          'RedHat' : {
              $pkg_name     = 'phpMyAdmin'
              $config_dir   = '/usr/share/phpMyAdmin'
              $config_file  = '/etc/phpMyAdmin/config.inc.php'
              $http_server  = 'httpd'
              $httpd_config = '/etc/phpMyAdmin/httpd.conf'
              $httpd_symlink= '/etc/httpd/conf.d/phpMyAdmin.conf'
              $gpg          = "/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${::os_maj_version}"

              # ensure epel repo
              yumrepo { 'epel':
                mirrorlist      => "http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${::os_maj_version}&arch=${::architecture}",
                failovermethod  => 'priority',
                enabled         => '1',
                gpgcheck        => '1',
                gpgkey          => "file://${gpg}",
                descr           => "Extra Packages for Enterprise Linux ${::os_maj_version} - ${::architecture}"
              }

              # ensure key
              file { $gpg:
                ensure      => present,
                owner       => 'root',
                group       => 'root',
                mode        => '0644',
                content     => template("phpmyadmin/RPM-GPG-KEY-EPEL-${::os_maj_version}")
              }

              # import key unless already done
              exec { 'import gpg' :
                command     => "rpm --import ${gpg}",
                unless      => "rpm -q gpg-pubkey-$(echo $(gpg --throw-keyids < ${gpg}) | cut --characters=11-18 | tr '[A-Z]' '[a-z]')",
                require     => File[$gpg]
              }
          }
          'Debian' : {
              $pkg_name      = 'phpmyadmin'
              $config_dir    = '/usr/share/phpmyadmin'
              $config_file   = '/etc/phpmyadmin/config.inc.php'
              $httpd_server  = 'apache2'
              $httpd_config  = '/etc/phpmyadmin/apache.conf'
              $httpd_symlink = '/etc/apache2/conf.d/phpmyadmin.conf'
          }
          default : {
              fail( "${::osfamily} not supported" )
          }
      }

      # install main package
      package { $pkg_name :
        ensure  => installed
      }

      # ensure web server
      package { $httpd_server :
        ensure  => installed
      }

      service { $httpd_server :
        ensure  => running,
        enable  => true,
        require => Package[$httpd_server]
      }

      File {
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        require => Package[$pkg_name],
      }

      # database connection config
      file { $config_file:
        content => template('phpmyadmin/config.inc.php.erb')
      }

      # webserver config
      file { $httpd_config:
        content    => template('phpmyadmin/httpd.conf.erb'),
        notify     => Service[$httpd_server]
      }

      # symlink
      file { $httpd_symlink:
        ensure     => 'link',
        target     => $httpd_config
      }

}
