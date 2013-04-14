class circus::manager {
    $check_delay = 5
    $endpoint = "tcp://127.0.0.1:5555"
    $stats_endpoint = "tcp://127.0.0.1:5557"

    package { ["libzmq-dev", "libevent-dev", "python-dev"]:
        ensure => installed,
    }

    package { ["circus", "greenlet", "gevent"]:
        ensure   => installed,
        provider => pip,
        require  => Package["libzmq-dev", "libevent-dev", "python-dev"];
    }

    service {
        "circusd":
            ensure  => running,
            enable  => true,
            provider => upstart,
            require => [
                File["/etc/init/circusd.conf"],
                File["/etc/circus.ini"],
                Package["circus"],
            ];
    }

    exec {
        "circusd-initctl-start":
            command => "/sbin/initctl start circusd",
            unless  => "/sbin/initctl status circusd | grep -w running",
            require => [
                Package["circus"],
                File["/etc/init/circusd.conf"],
                File["/etc/circus.ini"],
            ];
        "circus-initctl-reload":
            command     => "/sbin/initctl restart circusd",
            require     => Service['circusd'],
            refreshonly => true;
    }

    file {
        "/etc/init/circusd.conf":
            ensure  => file,
            mode    => 0644,
            owner   => "root",
            group   => "root",
            source  => "puppet:///modules/circus/circusd.conf";
        "/etc/circus.ini":
            ensure  => file,
            mode    => 0644,
            owner   => "root",
            group   => "root",
            content => template("circus/circus.ini"),
            notify  => Exec["circus-initctl-reload"];
        "/etc/circus.d":
            ensure  => directory,
            mode    => 0755,
            owner   => "root",
            group   => "root";
    }
}
