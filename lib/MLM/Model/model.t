#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use lib '../..';
use MLM::Model;

{
  package FakeDBH;
  sub new { bless {AutoCommit => 1, begin => 0, commit => 0, rollback => 0}, shift }
  sub begin_work { $_[0]->{begin}++ }
  sub commit { $_[0]->{commit}++ }
  sub rollback { $_[0]->{rollback}++ }
}

my $dbh = FakeDBH->new;
my $model = MLM::Model->new(dbh => $dbh);
my $structured = [3000, 'structured failure'];
my $err = $model->run_in_transaction(sub { return $structured });

is_deeply($err, $structured, 'structured transaction errors are returned unchanged');
is($dbh->{begin}, 1, 'transaction started');
is($dbh->{rollback}, 1, 'structured error rolls back');
is($dbh->{commit}, 0, 'structured error does not commit');

$dbh = FakeDBH->new;
$model = MLM::Model->new(dbh => $dbh);
$err = $model->run_in_transaction(sub { return 'plain failure' });

is($err, 'plain failure', 'scalar transaction errors are returned unchanged');
is($dbh->{rollback}, 1, 'scalar error rolls back');
is($dbh->{commit}, 0, 'scalar error does not commit');

$dbh = FakeDBH->new;
$model = MLM::Model->new(dbh => $dbh);
$err = $model->run_in_transaction(sub { return });

is($err, undef, 'successful transaction returns no error');
is($dbh->{rollback}, 0, 'successful transaction does not roll back');
is($dbh->{commit}, 1, 'successful transaction commits');

done_testing();
