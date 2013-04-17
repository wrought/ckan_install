exec { "apt-update":
  command => "/usr/bin/apt-get update"
}

# Ensure apt-get update has been run before installing any packages
Exec["apt-update"] -> Package <| |>

package {
    "python":
        ensure => installed,
        provider => apt;
    "python-dev":
        ensure => installed,
        provider => apt;
    "postgresql":
        ensure => installed,
        provider => apt;
    "libpq-dev":
        ensure => installed,
        provider => apt;
    "python-pip":
        ensure => installed,
        provider => apt;
    "python-virtualenv":
        ensure => installed,
        provider => apt;
    "git-core":
        ensure => installed,
        provider => apt;
    "solr-jetty":
        ensure => installed,
        provider => apt;
    "openjdk-6-jdk":
        ensure => installed,
        provider => apt;
    "curl":
        ensure => installed,
        provider => apt;
}

# TODO
# to remove manual steps from install.sh, must write to /etc/postgresql/9.1/main/pg_hba.conf

Package <| |> -> Exec["install"]

exec { "install":
  path => '/vagrant',
  command => './install.sh'
}

