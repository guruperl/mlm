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
my $member = MLM::Beacon->new(role=>"m");
$err = $member->get_credential("www","gmarketCool");
die $err if $err;
my $public = MLM::Beacon->new(role=>"p");

for (my $i=1; $i<10; $i++) {
  my %newuser = (
    "memberid"=>$i.$i.$i.$i,
    "action"=>"insert",
    "sidlogin"=>"www",
    "firstname"=>"Test0$i",
    "lastname"=>"TestLast0$i",
    "email"=>"genelet+0$i\@gmail.com",
    "login"=>"genelet0$i",
    "passwd"=>"1234abcd",
    "confirm"=>"1234abcd",
    "street"=>"999 st",
    "city"=>"el monte",
    "state"=>"ca",
    "country"=>"usa",
    "packageid"=>(($i>5)?($i-5):$i)
  );
  if ($i>4) {
    $newuser{sidlogin} = "genelet04";
  } elsif ($i>7){
    $newuser{sidlogin} = "genelet07";
  }
  my @user = %newuser;
  my $resp = $public->post_mockup("signup", [@user]);
  is($resp->code, 200, "status code is 200");

  $resp = $admin->post_mockup("member", [
	"action"=>"insert",
    "affiliate"=>888,
	"signupid"=>$i,
	"billingid"=>"internal testing id only",
	"paytype"=>"Manual"]);
  is($resp->code, 200, "status code is 200");

  if ($i==3) {
    $resp = $member->post_mockup("member", [
      "action"=>"changedef", 
      "defpid"=>"888", 
      "defleg"=>"R"]);
    is($resp->code, 200, "status code is 200");
  } elsif ($i==4) {
    $member = MLM::Beacon->new(role=>"m");
    $err = $member->get_credential("genelet04","1234abcd");
    die $err if $err;
    $resp = $member->post_mockup("member", [
      "action"=>"changedef", 
      "defpid"=>"4444", 
      "defleg"=>"R"]);
    is($resp->code, 200, "status code is 200");
  } elsif ($i==5) {
    $member = MLM::Beacon->new(role=>"m");
    $err = $member->get_credential("genelet04","1234abcd");
    die $err if $err;
    $resp = $member->post_mockup("member", [
      "action"=>"changedef", 
      "defpid"=>"4444", 
      "defleg"=>"L"]);
    is($resp->code, 200, "status code is 200");
  } elsif ($i==7) {
    $resp = $member->post_mockup("member", [
      "action"=>"changedef", 
      "defpid"=>"7777", 
      "defleg"=>"L"]);
    is($resp->code, 200, "status code is 200");
  } elsif ($i==8) {
    $resp = $member->post_mockup("member", [
      "action"=>"changedef", 
      "defpid"=>"7777", 
      "defleg"=>"R"]);
    is($resp->code, 200, "status code is 200");
  }
}

done_testing();
exit(0);
