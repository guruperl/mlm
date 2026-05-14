package MLM::Placement::Filter;

use strict;
use warnings;
use MLM::Filter;

use parent 'MLM::Filter';

sub preset {
	my $self = shift;
	my $err  = $self->SUPER::preset(@_);
	return $err if $err;

	my $ARGS   = $self->{ARGS};
	my $r      = $self->{R};
	my $who    = $ARGS->{g_role};
	my $action = $ARGS->{g_action};

	$ARGS->{max_plevel} = ($who eq 'a') ? $self->{CUSTOM}->{MAX_plevel} :
							$self->{CUSTOM}->{MAX_mplevel};
	$ARGS->{top_memberid} = $self->{CUSTOM}->{TOP_memberid};

	if ($action eq 'topics') {
		$ARGS->{sortby} = "level";
	}

	return;
}

sub before {
	my $self = shift;
	my $err  = $self->SUPER::before(@_);
	return $err if $err;

	my $ARGS   = $self->{ARGS};
	my $r      = $self->{R};
	my $who    = $ARGS->{g_role};
	my $action = $ARGS->{g_action};

  my ($form, $extra, $nextextras) = @_;

	if ($action eq 'topics') {
		$extra->{parent} = $ARGS->{memberid};
		$extra->{_gsql} = "level<=".$ARGS->{max_plevel};
	}

  return;
}

sub after {
	my $self = shift;
	my $err  = $self->SUPER::after(@_);
	return $err if $err;

	my $ARGS   = $self->{ARGS};
	my $r      = $self->{R};
	my $who    = $ARGS->{g_role};
	my $action = $ARGS->{g_action};

    my ($form) = @_;
    my $lists = $form->{LISTS};

	return;
}

1;
