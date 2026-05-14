package MLM::Sponsor::Model;

use strict;
use warnings;
use MLM::Model;
our $AUTOLOAD;

use parent 'MLM::Model';

sub topics {
  my $self = shift;
  my $err = $self->unilevel(@_);
  return $err if $err;

  delete $self->{OTHER}->{treetext};
  return;
}

sub view_sponsor {
  my $self = shift;
  my $err = $self->unilevel(@_);
  return $err if $err;

  $self->{LISTS} = [];
  return;
}

# use ref to construct a compicated link on downline
my $name = sub {
    my $item = shift;
	my $admin = shift;
  my $self = shift;
  my $login = $self->html_escape($item->{login});
  my $memberid = $self->html_escape($item->{memberid});
	return ($admin) ? "<a href='sponsor?action=view_sponsor&amp;memberid=$memberid'>".$login."<br>$memberid</a>" : $login;
};

sub unilevel {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  my $lists = [];
  my $err = $self->select_sql($lists,
"SELECT memberid, login, sid, active, m.typeid, t.short, countl, countr, firstname, lastname, signuptime
FROM member m
INNER JOIN def_type t USING (typeid)");
  return $err if $err;

  my $ref = {};
  my $children = {};
  for my $item (@$lists) {
    $ref->{$item->{memberid}} = $item;
    push @{$children->{$item->{sid}}}, $item->{memberid};
  }
  
  $self->{LISTS} = [];
  my $str = "<ul>\n\t<li>\n\t".$name->($ref->{$ARGS->{memberid}}, $ARGS->{_gadmin}, $self)."\n";
  $self->_lower_level($ref, $children, \$str, 0, $ARGS->{memberid});
  $str .= "\t</li>\n</ul>\n";

  $self->{OTHER}->{treetext} = $str;
  return;
}

sub _lower_level {
  my $self = shift;
  my ($ref, $children, $str, $i, $id) = @_;
  $ref->{$id}->{generation} = $i;
  push @{$self->{LISTS}}, $ref->{$id};
  my $lists = $children->{$id};
  return unless $lists;
  $i++;
  return if ($i >= $self->{ARGS}->{max_slevel});
  my $old     = "\t" x $i;
  my $leading = "\t" x ($i+1);
  $$str .= $old . "<ul>\n";
  for my $one (@$lists) {
    $$str .= $leading . "<li>\n" . $leading. $name->($ref->{$one}, $self->{ARGS}->{_gadmin}, $self) . "\n";
    $self->_lower_level($ref, $children, $str, $i, $one);
    $$str .= $leading . "</li>\n";
  }
  $$str .= $old . "</ul>\n";
  return;
}

1;
