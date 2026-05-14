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

# run_all_tests
my $resp = $admin->post_mockup("income", [
	"action"=>"run_all_tests",
	"c1_id"=>"0",
	"c4_id"=>"0",
	"start_monthly"=>"2000-1-1",
	"start_daily"=>"2000-1-1",
	"end_daily"=>"2100-1-1"
]);
is($resp->code, 200, "status code of run_all_tests is 200");
my $content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

# see ledger
$resp = $admin->get_mockup("ledger", "action=topics");
is($resp->code, 200, "status code of ledger topics is 200");
$content = JSON->new->utf8(0)->decode( $resp->content() );
die "Incorrect json return" unless ($content and $content->{data});

my $ref = {
888 => {balance=>1290.60, shop_balance=>143.40, amount=>1434.00},
4444=> {balance=>316.98,  shop_balance=>35.22,  amount=>352.20},
7777=> {balance=>27.00,   shop_balance=>3.00,   amount=>30.00},
3333=> {balance=>1.98,    shop_balance=>0.22,   amount=>2.20},
2222=> {balance=>1.98,    shop_balance=>0.22,   amount=>2.20},
1111=> {balance=>1.98,    shop_balance=>0.22,   amount=>2.20}};
for my $item (@{$content->{data}}) {
  is($item->{weekid}, 0,  "weekid is 0");
  my $id = $item->{memberid};
  for my $key (qw(balance shop_balance amount)) {
    ok(sprintf("%.2f", $item->{$key}) eq sprintf("%.2f", $ref->{$id}->{$key}), "check $key of $id");
  }
} 

done_testing();
exit;
