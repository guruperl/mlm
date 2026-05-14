package MLM::Packagedetail::Filter;

use strict;
use warnings;
use MLM::Filter;

use parent 'MLM::Filter';

sub preset {
#	my $self = shift;
#	my $err  = $self->SUPER::preset(@_);
#	return $err if $err;

#	my $ARGS   = $self->{ARGS};
#	my $r      = $self->{R};
#	my $who    = $ARGS->{g_role};
#	my $action = $ARGS->{g_action};

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
    $extra->{packageid} = $ARGS->{packageid};
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

  return unless ($action eq 'topics');

  $ARGS->{sumprice} = $ARGS->{sumbv} =$ARGS->{sumsh} = $ARGS->{sumnumold} = 0;
  foreach my $item (@$lists) {
    $ARGS->{sumnumold} += $item->{num};
    $ARGS->{sumprice} += $item->{num} * $item->{price};
    $ARGS->{sumbv} += $item->{num} * $item->{bv};
    $ARGS->{sumsh} += $item->{num} * $item->{sh};
  }


	return;
}

1;
