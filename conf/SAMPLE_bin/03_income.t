#!/usr/bin/perl

use FindBin qw($Bin);
use lib "$Bin/../../lib", "$Bin/../../../perl";
use strict;
use JSON;
use MLM::Beacon;
use Test::More;

my $admin = MLM::Beacon->new(role=>"a");
my $err = $admin->get_credential("gmarket","gmarketIsCool");
die $err if $err;

# direct bonus
my $resp = $admin->post_mockup("income", [
	"action"=>"week4_direct",
	"c4_id"=>"0",
	"start_monthly"=>"2000-1-1",
	"end_daily"=>"2100-1-1"
]);
is($resp->code, 200, "status code is 200");
my $content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

my $two;
for my $item (@{$content->{data}}) {
  ok($item->{classify} eq 'direct',  "type is direct");
  is($item->{lev}, 1, "lev is 1");
  is($item->{amount}, 1, "amount is always 1 for 888 and 4444");
  $two->{$item->{memberid}} += $item->{refid};
}
is($two->{888},  1+2+3+4,   "total typeid plus for 888");
is($two->{4444}, 1+2+3+4+5, "total typeid plus for 4444");

# binary
$resp = $admin->post_mockup("income", [
	"action"=>"week1_binary",
	"c1_id"=>"0",
	"start_daily"=>"2000-1-1",
	"end_daily"=>"2100-1-1"
]);
is($resp->code, 200, "status code is 200");
$content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

for my $item (@{$content->{data}}) {
  ok($item->{weekid} eq '0',  "weekid is 0");
  ok($item->{classify} eq 'binary',  "type is binary");
  if ($item->{memberid} == 888) {
    is($item->{lev}, 11, " 1 vs 1");
    is($item->{amount}, 10, "10 units");
    is($item->{refid}, 12, "the other 12 units");
  } elsif ($item->{memberid} == 7777) {
    is($item->{lev}, 21, " 2 vs 1");
    is($item->{amount}, 1, "1 unit only");
    is($item->{refid}, 2, "the other 2 units");
  }
}

# match
$resp = $admin->post_mockup("income", [
	"action"=>"week1_match",
	"c1_id"=>"0",
	"start_daily"=>"2000-1-1",
	"end_daily"=>"2100-1-1"
]);
is($resp->code, 200, "status code is 200");
$content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

my $total = 0;
for my $item (@{$content->{data}}) {
  ok($item->{weekid} eq '0',  "weekid is 0");
  ok($item->{classify} eq 'matchup',  "type is matchup");
  ok($item->{memberid} eq '888',  "member is 888");
  ok($item->{lev} eq '2',  "lev is 2");
  is($item->{amount}, 1,  "amount is 1");
  $total += $item->{refid};
}
is($total, 1+2+3+4+5, "total typeid is 15");

# asffiliate
$resp = $admin->post_mockup("income", [
	"action"=>"week1_affiliate",
	"c1_id"=>"0",
	"start_daily"=>"2000-1-1",
	"end_daily"=>"2100-1-1"
]);
is($resp->code, 200, "status code is 200");
$content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

$total = 0;
my $num = 0;
for my $item (@{$content->{data}}) {
  ok($item->{weekid} eq '0',  "weekid is 0");
  ok($item->{classify} eq 'affiliate',  "type is affiliate");
  ok($item->{memberid} eq '888',  "member is 888");
  ok($item->{lev} eq '1',  "lev is 1");
  $total += $item->{refid};
  $num += $item->{amount};
}
is($total, 1+2+3+4+5, "total typeid is 15");
is($num, 2+2+2+2+1, "total num is 9");

done_testing();
exit;
