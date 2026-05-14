#!/usr/bin/perl
# Unit tests for MLM::Income::Model

package IncomeTest;

use strict;
use warnings;
use Test::More;
use base qw(Test::Class);

use lib '../..';
use MLM::Income::Model;
use MLM::Income::Filter;

# Test that module loads correctly
sub test_module_loads : Test(2) {
    my $self = shift;
    use_ok('MLM::Income::Model');
    use_ok('MLM::Income::Filter');
}

# Test inheritance
sub test_inheritance : Test(2) {
    my $self = shift;
    ok(MLM::Income::Model->isa('MLM::Model'), 'Model inherits from MLM::Model');
    ok(MLM::Income::Filter->isa('MLM::Filter'), 'Filter inherits from MLM::Filter');
}

# Test that key compensation methods exist
sub test_model_methods_exist : Test(16) {
    my $self = shift;
    # Core methods
    can_ok('MLM::Income::Model', 'inserts');
    can_ok('MLM::Income::Model', 'run_daily');
    can_ok('MLM::Income::Model', 'run_cron');
    can_ok('MLM::Income::Model', 'run_all_tests');
    can_ok('MLM::Income::Model', 'run_to_yesterday');

    # Affiliate bonus methods
    can_ok('MLM::Income::Model', 'is_week1_affiliate');
    can_ok('MLM::Income::Model', 'week1_affiliate');
    can_ok('MLM::Income::Model', 'done_week1_affiliate');
    can_ok('MLM::Income::Model', 'weekly_affiliate');

    # Binary/Pairing bonus methods
    can_ok('MLM::Income::Model', 'is_week1_binary');
    can_ok('MLM::Income::Model', 'week1_binary');
    can_ok('MLM::Income::Model', 'done_week1_binary');
    can_ok('MLM::Income::Model', 'weekly_binary');

    # Direct/Unilevel bonus methods
    can_ok('MLM::Income::Model', 'is_week4_direct');
    can_ok('MLM::Income::Model', 'week4_direct');
    can_ok('MLM::Income::Model', 'monthly_direct');
}

# Test match bonus methods
sub test_match_methods_exist : Test(4) {
    my $self = shift;
    can_ok('MLM::Income::Model', 'is_week1_match');
    can_ok('MLM::Income::Model', 'week1_match');
    can_ok('MLM::Income::Model', 'done_week1_match');
    can_ok('MLM::Income::Model', 'weekly_match');
}

sub test_filter_methods_exist : Test(3) {
    my $self = shift;
    can_ok('MLM::Income::Filter', 'preset');
    can_ok('MLM::Income::Filter', 'before');
    can_ok('MLM::Income::Filter', 'after');
}

# Test Filter security helper methods inherited from MLM::Filter
sub test_filter_security_helpers : Test(4) {
    my $self = shift;
    can_ok('MLM::Income::Filter', 'escape_like_value');
    can_ok('MLM::Income::Filter', 'validate_column');
    can_ok('MLM::Income::Filter', 'validate_date_part');
    can_ok('MLM::Income::Filter', 'build_like_sql');
}

sub test_run_to_yesterday_clears_stale_flags : Test(4) {
    my $self = shift;

    my $model = bless {
        ARGS => {},
        seen => [],
    }, 'IncomeRunToYesterdayTest';

    my $err = $model->run_to_yesterday();
    is($err, undef, 'run_to_yesterday succeeds');
    is(scalar @{$model->{seen}}, 2, 'two pending periods were processed');
    is($model->{seen}->[0]->{to_run_binary}, 1, 'first period runs binary');
    ok(!$model->{seen}->[1]->{to_run_binary} && $model->{seen}->[1]->{to_run_match},
        'second period does not inherit stale binary flag');
}

package IncomeRunToYesterdayTest;

use parent 'MLM::Income::Model';

sub select_sql {
    my ($self, $arr) = @_;
    push @$arr,
        {
            c1_id => 10,
            daily => '2024-01-08',
            start_daily => '2024-01-01',
            end_daily => '2024-01-07',
            statusBinary => 'No',
            statusUp => 'Yes',
            statusAffiliate => 'Yes',
            status => 'Yes',
        },
        {
            c1_id => 11,
            daily => '2024-01-15',
            start_daily => '2024-01-08',
            end_daily => '2024-01-14',
            statusBinary => 'Yes',
            statusUp => 'No',
            statusAffiliate => 'Yes',
            status => 'Yes',
        };
    return;
}

sub call_once { return }

sub run_cron {
    my $self = shift;
    push @{$self->{seen}}, {
        map { $_ => $self->{ARGS}->{$_} }
        qw(c1_id c4_id to_run_direct to_run_binary to_run_match to_run_affiliate)
    };
    return;
}

package main;

Test::Class->runtests;
