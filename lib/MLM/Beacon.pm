package MLM::Beacon;

use strict;
use warnings;
BEGIN {
  my $root = __FILE__;
  $root =~ s{/lib/MLM/Beacon\.pm$}{};
  my $genelet_lib = $ENV{GENELET_LIB} || "$root/../perl";
  unshift @INC, $genelet_lib if -d $genelet_lib;
}
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use Genelet::Dispatch;
use Genelet::Beacon;

use parent 'Genelet::Beacon';

sub _repo_root {
  my $file = abs_path(__FILE__);
  return dirname(dirname(dirname($file)));
}

sub _config {
  my $root = _repo_root();
  my $config_path = $ENV{MLM_CONFIG} || File::Spec->catfile($root, qw(conf config.json));
  $config_path = File::Spec->catfile($root, qw(conf SAMPLE_config.json)) unless -e $config_path;

  my $config = Genelet::Dispatch::get_hash($config_path);

  my $replace_sample = sub {
    my $value = shift;
    return $value unless defined $value;
    $value =~ s{/SAMPLE_home/mlm}{$root}g;
    $value =~ s{SAMPLE_domain}{localhost}g;
    return $value;
  };

  for my $key (qw(Document_root Server_url Template Uploaddir)) {
    $config->{$key} = $replace_sample->($config->{$key});
  }
  if ($config->{Log}) {
    my $log_dir = File::Spec->catdir($root, 'logs');
    make_path($log_dir) unless -d $log_dir;
    $config->{Log}->{filename} = File::Spec->catfile($log_dir, 'debug.log');
  }

  $config->{Db} = [
    $ENV{MLM_DB_DSN} || 'dbi:mysql:database=mlm_test;host=127.0.0.1;port=53307',
    $ENV{MLM_DB_USER} || 'mlm',
    $ENV{MLM_DB_PASSWORD} || 'mlm'
  ] if ($config_path =~ /SAMPLE_config\.json$/ || $ENV{MLM_DB_DSN});

  for my $role (keys %{$config->{Roles} || {}}) {
    for my $key (qw(Secret Coding Domain Logout)) {
      $config->{Roles}->{$role}->{$key} = $replace_sample->($config->{Roles}->{$role}->{$key});
    }
  }
  $config->{Secret} =~ s/SAMPLE_random/static_test_secret/g if $config->{Secret};

  return $config;
}

__PACKAGE__->setup_accessors(
  config => _config(),
  lib    => $ENV{MLM_LIB} || File::Spec->catdir(_repo_root(), 'lib'),
  ip     => '192.168.29.29',
  comps  => ["Admin","Affiliate","Signup","Member","Sponsor","Placement","Category","Gallery","Package", "Packagedetail","Packagetype","Sale","Basket","Lineitem","Income","Incomeamount","Ledger","Tt","Ttpost","Week1","Week4","Affiliate"],
  tag    => 'json',
  header => {'Content-Type' => "application/x-www-form-urlencoded", 'Cookie' => "go_probe=1"}
);

1;
