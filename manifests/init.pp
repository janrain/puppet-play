# Class: play
#
# This module manages play framework applications and modules.
# The class itself installs Play 1.2.3 in /opt/play-1.2.3
#
# Actions:
#  play::module checks the availability of a Play module. It installs
#  it if not found
#  play::application starts a play application
#  play::service starts a play application as a system service
#
# Parameters:
# *version* : the Play version to install
#
# Requires:
# wget puppet module https://github.com/EslamElHusseiny/puppet-wget
# A proper java installation and JAVA_HOME set
# Sample Usage:
#  include play
#  play::module {"mongodb module" :
# 	module  => "mongo-1.3",
#	require => [Class["play"], Class["mongodb"]]
#  }
#
#  play::module { "less module" :
# 	module  => "less-0.3",
#	require => Class["play"]
#  }
#
#  play::service { "bilderverwaltung" :
#	path    => "/home/clement/demo/bilderverwaltung",
#	require => [Jdk6["Java6SDK"], Play::Module["mongodb module"]]
#  }
#
class play ($version = "2.1.1", $install_path = "/opt", $bucket = 'puppet-filesource', $key = "play-framework/play-${version}.zip") {

## We don't need to use this module
#	include wget

  ## $bucket is the aws bucket to pull from
  ## $key is the full path to the file in the bucket
  ## $filename is the name to download the package as.
  $play_version  = $version
  $filename      = "play-${play_version}.zip"
  $play_path     = "${install_path}/play-${play_version}"
  $curl_url      = s3getcurl($bucket, $key, $filename, 300)
# Make sure files aren't uploaded to s3 in multipart
  $file_checksum = s3getEtag($bucket, $key)
  notice("Installing Play ${play_version}")
  exec { 'download-play-framework' :
    command => "$curl_url; mv ${filename} ${install_path}/",
    cwd => '/tmp',
    #path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    unless => "echo \"$file_checksum  $install_path/$filename\" | md5sum -c --status",
    require => Exec['mkdir.play.install.path'],
  }

  exec { "mkdir.play.install.path":
    command => "/bin/mkdir -p ${install_path}",
    unless  => "test -d ${install_path}"
  }

  exec {"unzip-play-framework":
    cwd     => "${install_path}",
    command => "/usr/bin/unzip ${install_path}/play-${play_version}.zip",
    unless  => "test -d $play_path",
    require => [ Package["unzip"], Exec["download-play-framework"], Exec["mkdir.play.install.path"] ],
  }

  file { "$play_path/play":
    ensure  => file,
    owner   => "root",
    mode    => "0755",
    require => [Exec["unzip-play-framework"]]
  }

  file {'/usr/bin/play':
    ensure  => 'link',
    target  => "$play_path/play",
    require => File["$play_path/play"],
  }

  # Add a unversioned symlink to the play installation.
  file { "${install_path}/play":
    ensure => link,
    target => $play_path,
    require => Exec["mkdir.play.install.path", "unzip-play-framework"]
  }

  if !defined(Package['unzip']){ package{"unzip": ensure => installed} }
}
