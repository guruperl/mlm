#!/usr/bin/perl

use FindBin qw($Bin);
use lib "$Bin/../../lib", "$Bin/../../../perl";
use strict;
use Data::Dumper;
use JSON;
use MLM::Beacon;
use Test::More;

my $member = MLM::Beacon->new(role=>"m");
my $err = $member->get_credential("genelet04","1234abcd");
die $err if $err;

my $resp = $member->post_mockup("basket", [
	"action"=>"insert",
	"classify"=>"gallery",
	"id"=>"1",
	"qty"=>"1"
]);
is($resp->code, 200, "status code is 200");
my $content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

$resp = $member->post_mockup("basket", [
	"action"=>"insert",
	"classify"=>"gallery",
	"id"=>"2",
	"qty"=>"1"
]);
is($resp->code, 200, "status code is 200");
$content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

$resp = $member->post_mockup("sale", [
	"action"=>"buy",
	"agreebalance"=>"Yes"
]);
is($resp->code, 200, "status code is 200");
$content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

$resp = $member->get_mockup("ledger", "action=topics");
is($resp->code, 200, "status code is 200");
$content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

for my $item (@{$content->{data}}) {
  if ($item->{status} eq 'Weekly') {
    is($item->{balance}, 316.98, "original balance 216.98");
  } elsif ($item->{status} eq 'Shopping') {
    ok(sprintf("%.2f",$item->{balance}) eq sprintf("%.2f", 22.20), "after shopping, the balance 22.20");
  }
}

done_testing();
exit(0);
