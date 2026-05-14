package MLM::Member::Model;

use strict;
use warnings;
use MLM::Model;
use MLM::Constants qw(
    ERR_LOGIN_EXISTS
    ERR_SPONSOR_NOT_FOUND
    ERR_PID_NOT_EXISTS
    ERR_PLACEMENT_NOT_UNDER_SPONSOR
    ERR_POSITION_TAKEN
    ERR_SID_IS_SELF
);
our $AUTOLOAD;

use parent 'MLM::Model';

sub dashboard {
  my $self = shift;
  return $self->edit(shift) || $self->process_after("dashboard", @_);
}

sub insert {
  my $self = shift;
  my @args = @_;

  return $self->run_in_transaction(sub {
    return $self->SUPER::insert(@args);
  });
}
  
sub startnew {
  my $self = shift;
  my $extra = shift;

  return $self->get_args($self->{ARGS},
"SELECT login AS sidlogin
FROM member
WHERE login=? AND active='Yes'", $self->{ARGS}->{slogin})
  || $self->process_after("startnew", @_)
}

sub bulk {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  my $daily = shift;
  my $str = ($daily && $daily->{upto})
	? "AND date(signuptime)<='".$daily->{upto}."'"
	: "";

  my $arr = [];
  my $err = $self->select_sql($arr,
"SELECT signupid, sidlogin, memberid, login, passwd, email, firstname,
    lastname, street, city, state, zip, country, ip,
    signuptime, pid, leg, member_signup.packageid,
    typeid, price AS amount, bv AS credit
FROM member_signup
INNER JOIN product_package USING (packageid)
WHERE signupstatus='Bulk' $str
ORDER BY signuptime, signupid");
  return $err if $err;

  $ARGS->{active} = 'Yes';
  $ARGS->{classify} = 'package';
  $ARGS->{paystatus} = "Processing";
  $ARGS->{signuptype} = "Yes";
  $ARGS->{inbasket} = "No";

  for my $item (@$arr) {
    while (my ($k, $v) = each %$item) {
      $ARGS->{$k} = $v;
    }
    $ARGS->{id} = $ARGS->{packageid}; #in baske, id is for package and gallery
    $ARGS->{remark} = $ARGS->{ip}; #for new signup, we put ip here
    $ARGS->{defpid} = $ARGS->{memberid}; # default_pid is himself
    $ARGS->{defleg} = $ARGS->{leg};      # default_leg is the same as him
    $err = $self->sponsor_top_pid();
    return $err if $err;
    my $hash;
    for my $name (@{$self->{INSERT_PARS}}) {
      $hash->{$name} = $ARGS->{$name} if $ARGS->{$name};
    }
    $err = $self->run_in_transaction(sub {
      return $self->insert_hash($hash)
		|| $self->call_once({model=>"basket", action=>"insert"})
		|| $self->call_once({model=>"sale", action=>"insert"})
		|| $self->call_once({model=>"lineitem", action=>"insert"})
		|| $self->call_once({model=>"signup", action=>"signup_update"})
		|| $self->call_once({model=>"signup", action=>"add_family"})
		|| $self->call_once({model=>"signup", action=>"add_miles"});
    });
    return $err if $err;
    delete $self->{OTHER}->{"basket_insert"};
    delete $ARGS->{"basketid"};
    delete $self->{OTHER}->{"sale_insert"};
    delete $ARGS->{"saleid"};
    delete $self->{OTHER}->{"lineitem_insert"};
    delete $ARGS->{"lineitemid"};
    delete $self->{OTHER}->{"signup_signup_update"};
    delete $self->{OTHER}->{"signup_add_family"};
    delete $self->{OTHER}->{"signup_add_miles"};
  }
  return;
}

sub get_signup {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  return $self->get_args($ARGS,
"SELECT sidlogin, memberid, login, passwd, email, firstname, lastname,
	street, city, state, zip, country, ip,
	signuptime, pid, leg, member_signup.packageid,
	typeid, price AS amount, bv AS credit
FROM member_signup
INNER JOIN product_package USING (packageid)
WHERE signupid=?", $ARGS->{signupid});
}

sub sponsor_top_pid {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  my $err = $self->get_args($ARGS,
"SELECT 1 AS one FROM member WHERE login=?", $ARGS->{login});
  return $err if $err;
  return ERR_LOGIN_EXISTS if $ARGS->{one}; # new account already exists

  $err = $self->get_args($ARGS,
"SELECT memberid AS sid, defpid AS defdefpid, defleg AS defdefleg
FROM member
WHERE login=? AND active='Yes'", $ARGS->{sidlogin});
  return $err if $err;
  return ERR_SPONSOR_NOT_FOUND unless $ARGS->{sid}; # this assigned upline does exists

  if ($ARGS->{pid}) { # if binary upline is given
	$err = $self->get_args($ARGS,
"SELECT 1 AS is_pid FROM member WHERE memberid=?", $ARGS->{pid});
	return $err if $err;
	return [ERR_PID_NOT_EXISTS, $ARGS->{pid}] unless $ARGS->{is_pid};
    
    unless ($ARGS->{sid} == $ARGS->{pid}) {
      $err = $self->get_args($ARGS,
"SELECT 1 AS two FROM family WHERE parent=? and child=?",
		$ARGS->{sid}, $ARGS->{pid});
      return $err if $err;
      return ERR_PLACEMENT_NOT_UNDER_SPONSOR unless $ARGS->{two}; # the b-upline must be a child of sponsor
    }
    $err = $self->get_args($ARGS,
"SELECT 1 AS three FROM member WHERE pid=? AND leg=?",
		$ARGS->{pid}, $ARGS->{leg});
    return $err if $err;
    return ERR_POSITION_TAKEN if $ARGS->{three}; # it already has child on that leg
  } elsif ($ARGS->{defdefpid}) { # use whoever the sponsor assigned by himself
    unless ($ARGS->{sid} == $ARGS->{defdefpid}) {
      $err = $self->get_args($ARGS,
"SELECT 1 AS four FROM family WHERE parent=? and child=?",
		$ARGS->{sid}, $ARGS->{defdefpid});
      return $err if $err;
      return ERR_PLACEMENT_NOT_UNDER_SPONSOR unless $ARGS->{four};  # the b-upline must be a child in b-tree
    }
    $err = $self->get_args($ARGS,
"SELECT 1 AS five FROM member WHERE pid=? AND leg=?",
		$ARGS->{defdefpid}, $ARGS->{defdefleg});
    return $err if $err;
    unless ($ARGS->{five}) { # ok, that position is not occupied in the b-tree
      $ARGS->{pid} = $ARGS->{defdefpid};
      $ARGS->{leg} = $ARGS->{defdefleg};
    }
  }

  unless ($ARGS->{pid}) { # no b-upline found, we assign the last one in leg L 
    $err = $self->get_args($ARGS,
"SELECT child AS pid FROM family WHERE parent=? ORDER BY level DESC LIMIT 1",
		$ARGS->{sid});
    return $err if $err;
    $ARGS->{pid} ||= 888; # this is the first user after 888 in table member
    $ARGS->{leg} = 'L';
  }

  $err = $self->get_args($ARGS,
"SELECT leg AS pidleg, top AS pidtop FROM member
WHERE memberid=?", $ARGS->{pid});
  if ($ARGS->{leg} eq $ARGS->{pidleg}) {
    $ARGS->{top} = $ARGS->{pidtop};
  } else {
    $ARGS->{top} = $ARGS->{pid};
  }

  delete $ARGS->{defdefpid};
  delete $ARGS->{defdefleg};
  delete $ARGS->{pidleg};
  delete $ARGS->{pidtop};

  return;
}

sub startdef {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  return $self->get_args($ARGS,
"SELECT defpid, defleg
FROM member
WHERE memberid=?", $ARGS->{memberid})
}

sub changedef {
  my $self = shift;

  return $self->do_sql(
"UPDATE member
SET defpid=?, defleg=?
WHERE memberid=?", map {$self->{ARGS}->{$_}} qw(defpid defleg memberid));
}

sub resetsid {
	my $self = shift;
	my $ARGS = $self->{ARGS};

    return ERR_SID_IS_SELF if ($ARGS->{newsid}==$ARGS->{memberid});
	return $self->do_sql(
"UPDATE member
SET sid=?, active=?
WHERE memberid=?", map {$ARGS->{$_}} qw(newsid newactive memberid));
}

sub resetpass {
  my $self = shift;

  return $self->do_sql(
"UPDATE member
SET passwd=SHA1(CONCAT(login,?))
WHERE memberid=?", map {$self->{ARGS}->{$_}} qw(newpasswd memberid));
}

sub changepass {
  my $self = shift;

  return $self->do_sql(
"UPDATE member
SET passwd=SHA1(concat(login, ?))
WHERE memberid=? AND passwd=SHA1(concat(login, ?))",
map {$self->{ARGS}->{$_}} qw(newpasswd memberid passwd));
}

sub edit {
  my $self = shift;

  return $self->get_args($self->{ARGS},
"SELECT COUNT(*) AS counts 
FROM member WHERE sid=?", $self->{ARGS}->{memberid}) || $self->SUPER::edit(@_);
}

1;
