package MLM::Sale::Model;

use strict;
use warnings;
use MLM::Model;
use MLM::Constants qw(ERR_INSUFFICIENT_FUNDS ERR_INSUFFICIENT_SHOP_BALANCE);
our $AUTOLOAD;

use parent 'MLM::Model';

sub myInvoice {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  $self->{LISTS} = [];
  return $self->select_sql($self->{LISTS},
"SELECT s.saleid, s.amount, s.credit, s.paytype, s.paystatus,p.title, b.qty
FROM sale s JOIN def_type t ON s.typeid = t.typeid
JOIN sale_lineitem i ON s.saleid = i.saleid
JOIN sale_basket b ON i.basketid = b.basketid
join product_package p on b.id = p.packageid
where b.classify = 'package' AND s.saleid=?
union all
SELECT s.saleid, s.amount, s.credit, s.paytype, s.paystatus,g.title, b.qty
FROM sale s JOIN def_type t ON s.typeid = t.typeid
JOIN sale_lineitem i ON s.saleid = i.saleid
JOIN sale_basket b ON i.basketid = b.basketid
join product_gallery g on b.id = g.galleryid
where b.classify = 'gallery' AND s.saleid=?", $ARGS->{saleid}, $ARGS->{saleid});
}
  
sub buy {
  my $self = shift;
  my $ARGS = $self->{ARGS};
  my $extra = shift;

  my $err = $self->call_once({model=>"basket", action=>"topics"});
  return $err if $err;

  my $need = $ARGS->{amount} + $ARGS->{shipping};
  my $ledger = $self->{OTHER}->{ledger_currentBalance}->[0];
  my $have = $ledger->{balance} + $ledger->{shop_balance};
  my $d1 = 0;
  my $d2 = 0;
  if ($have<$need) {
    return ERR_INSUFFICIENT_FUNDS;
  } elsif ($ledger->{shop_balance}<$need) {
    return ERR_INSUFFICIENT_SHOP_BALANCE unless ($ARGS->{agreebalance} eq 'Yes');
    $d1 = $ledger->{shop_balance};
    $d2 = $need - $d1;
  } else {
    $d1 = $need;
  }

  $err = $self->run_in_transaction(sub {
    $err = $self->do_sql(
      "INSERT INTO sale (memberid, amount, credit, shipping, paytype, paystatus, typeid, active, created)
       VALUES (?, ?, ?, ?, 'Advanced', 'Processing', ?, 'Yes', NOW())",
      $ARGS->{memberid}, $ARGS->{amount}, $ARGS->{credit}, $ARGS->{shipping}, $ARGS->{shop_typeid}
    );
    return $err if $err;

    my $saleid = $self->last_insertid();
    my @basket_items = @{$self->{OTHER}->{basket_topics}};

    if (@basket_items) {
      # Parameterized bulk insert for sale_lineitem
      my $str1 = "INSERT INTO sale_lineitem (saleid, basketid, amount, credit) VALUES " .
                 join(',', ("(?, ?, ?, ?)") x @basket_items);
      my @params1 = map { ($saleid, $_->{basketid}, $_->{amount} + $_->{shipping}, $_->{credit}) } @basket_items;
      $err = $self->do_sql($str1, @params1);
      return $err if $err;

      # Parameterized update for sale_basket
      my $str2 = "UPDATE sale_basket SET inbasket='No' WHERE memberid=? AND basketid IN (" .
                 join(',', ("?") x @basket_items) . ")";
      my @params2 = ($ARGS->{memberid}, map { $_->{basketid} } @basket_items);
      $err = $self->do_sql($str2, @params2);
      return $err if $err;
    }

    $err = $self->do_sql(
      "INSERT INTO income_ledger (memberid, amount, balance, shop_balance, old_ledgerid, weekid, created, status)
       VALUES (?,?,?,?,?,?,NOW(),'Shopping')",
      $ARGS->{memberid}, -1*$need, $ledger->{balance}-$d2, $ledger->{shop_balance}-$d1, $ledger->{ledgerid}, $ledger->{weekid}
    );
    return $err if $err;
    return;
  });
  return $err if $err;

  return;
}

1;
