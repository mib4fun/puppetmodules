# === Class proftpd
class proftpd {

    $proftpd    = hiera_hash('proftpd')
    $settings   = $proftpd['settings']
    $sftp       = $proftpd['sftp']

    $pkgs_name  = $::osfamily ? {
        'Debian'    => [ 'proftpd-basic', 'proftpd-mod-vroot' ],
        'RedHat'    => 'proftpd',
        default     => fail( "${::osfamily} not supported ")
    }

    $config_file = $::osfamily ? {
        'Debian'    => '/etc/proftpd/proftpd.conf',
        'RedHat'    => '/etc/proftpd.conf',
        default     => fail( "${::osfamily} not supported ")

    }

    # install packages
    package { $pkgs_name :
        ensure  => installed
    }

    package { 'pwgen' :
        ensure  => installed
    }

    service { 'proftpd' :
        ensure  => 'running',
        enable  => true
    }

    group { $settings['group'] :
        ensure  => present
    } ->

    user { $settings['user'] :
        ensure  => present,
        home    => '/var/run/proftpd',
        gid     => $settings['group'],
        shell   => '/bin/false'
    }

    File {
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0644',
        require => Package[$pkgs_name]
    }

    file { $config_file : 
        content => template('proftpd/proftpd.conf.erb'),
        notify  => Service['proftpd']
    }

    file { [ '/etc/proftpd', '/etc/proftpd/sftp.d' , '/etc/proftpd/messages.d' ] :
        ensure  => directory,
        mode    => '0755'
    }
    
    # modules conf
    file { '/etc/proftpd/modules.conf' :
        content => template('proftpd/modules.conf.erb')
    }

    # script pour creer de nouveau utilisateur ftp/sftp
    file { '/usr/local/sbin/new_ftp_account' :
        mode    => '0755',
        content => template('proftpd/new_ftp_account.sh')
    }

    # create sftp instances
    each($sftp) { | $index, $value |
        File['/etc/proftpd/sftp.d'] ->
        proftpd::sftp { "install sftp vhost - ${value} ":
            settings    => $sftp[$index]
        }
   }
}
