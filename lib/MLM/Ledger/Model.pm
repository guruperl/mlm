package MLM::Ledger::Model;

use strict;
use warnings;
use MLM::Model;
our $AUTOLOAD;

use parent 'MLM::Model';

sub currentBalance {
  my $self = shift;
  my $extra = shift;

  $self->{LISTS} = [];
  return $self->select_sql($self->{LISTS},
"SELECT l.weekid, l.memberid, l.ledgerid, l.balance, l.shop_balance
FROM income_ledger l
INNER JOIN view_balance v USING (ledgerid)
WHERE l.memberid=?", $extra->{memberid} || $self->{ARGS}->{memberid});
}

sub addShopping {
  my $self = shift;
  my $extra = shift;
  my $ARGS = $self->{ARGS};
  
  my $err = $self->currentBalance();
  return $err if $err;
  my $hash = $self->{LISTS}->[0];
  return $self->do_sql(
"INSERT INTO income_ledger (memberid, weekid, amount, balance, shop_balance, old_ledgerid, status, remark, manager, created) VALUES (?,?,?,?,?,?,?,?,?,NOW())",
$ARGS->{memberid}, $hash->{weekid}, $ARGS->{amount}, $hash->{balance}, $hash->{shop_balance}+$ARGS->{amount}, $hash->{ledgerid}, $ARGS->{status}, $ARGS->{remark}, $ARGS->{manager});
}
 
1;
