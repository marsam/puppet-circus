class circus::manager {
    $check_delay = 5
    $endpoint = "tcp://127.0.0.1:5555"
    $stats_endpoint = "tcp://127.0.0.1:5557"

    package { ["libzmq-dev", "libevent-dev", "python-dev"]:
        ensure => installed,
    }

    package { ["circus", "circus-web", "gevent"]:
        ensure   => installed,
        provider => pip,
        require  => Package["libzmq-dev", "libevent-dev", "python-dev"];
    }

    service { "circusd":
        ensure  => running,
        enable  => true,
        provider => upstart,
        require => [
            Package["circus"],
            File["/etc/init/circusd.conf"],
            File["/etc/circus.ini"],
            File["/etc/init.d/circusd"],
        ];
    }

    if versioncmp($puppetversion, '2.7.14') <= 0 {
        # Create a symlink to /etc/init/*.conf in /etc/init.d, because Puppet 2.7.14
        # looks there incorrectly (see: http://projects.puppetlabs.com/issues/14297)
        file { "/etc/init.d/circusd":
            ensure => link,
            target => '/lib/init/upstart-job',
        }
    }

    file { "/etc/init/circusd.conf":
        ensure  => file,
        mode    => 0644,
        owner   => "root",
        group   => "root",
        source  => "puppet:///modules/circus/circusd.conf",
    }

    file { "/etc/circus.ini":
        ensure  => file,
        mode    => 0644,
        owner   => "root",
        group   => "root",
        content => template("circus/circus.ini"),
        notify  => Service['circusd'],
    }
    file { "/etc/circus.d":
        ensure  => directory,
        mode    => 0755,
        owner   => "root",
        group   => "root";
    }
}
