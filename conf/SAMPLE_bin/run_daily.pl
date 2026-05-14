#!/usr/bin/perl

use lib qw(/SAMPLE_home/mlm/lib /SAMPLE_home/perl);
use strict;
use Data::Dumper;
use JSON;
use MLM::Beacon;

my $admin = MLM::Beacon->new(role=>"a");
my $err = $admin->get_credential("gmarket","gmarketIsCool");
die $err if $err;

my $resp = $admin->post_mockup("income", ["action"=>"run_daily"]);
die Dumper $resp unless ($resp->code == 200);
my $content = JSON->new->utf8(0)->decode( $resp->content() );
die $resp->content() unless ($content and $content->{data});

exit;
