package MLM::Signup::Model;

use strict;
use warnings;
use MLM::Model;
our $AUTOLOAD;

use parent 'MLM::Model';

sub bulk {
  my $self = shift;
  return $self->get_args($self->{ARGS},
"SELECT count(*) AS counts
FROM member_signup WHERE signupstatus='Bulk'");
}

sub insert {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  my $err = $self->get_args($ARGS,
"SELECT 1 AS one FROM member WHERE login=?", $ARGS->{login});
  return $err if $err;
  return 3103 if $ARGS->{one}; # new account already exists
  $err = $self->get_args($ARGS,
"SELECT 1 AS one FROM member_signup WHERE login=? AND signupstatus='Yes'", $ARGS->{login});
  return $err if $err;
  return 3103 if $ARGS->{one}; # new account already exists

  return $self->SUPER::insert(@_);
}

sub signup_update {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  return $self->do_sql(
"UPDATE member_signup SET signupstatus='No' WHERE signupid=?",
$ARGS->{signupid})
#"UPDATE member SET defpid=NULL, defleg=NUL
	|| $self->do_sql(
"UPDATE member SET defpid=?
WHERE defpid=? AND defleg=?", $ARGS->{memberid}, $ARGS->{pid}, $ARGS->{leg});
}

sub add_family {
  my $self = shift;
  my $ARGS = $self->{ARGS};

  return $self->do_sql(
"INSERT INTO family (parent, leg, child, level, created)
SELECT parent, leg, '".$ARGS->{memberid}."', level+1, NOW()
FROM family WHERE child=?", $ARGS->{pid})
	|| $self->do_sql(
"INSERT INTO family (parent, leg, child, level, created)
VALUES (?,?,?,1,NOW())", $ARGS->{pid}, $ARGS->{leg}, $ARGS->{memberid});

  return;
}

sub add_miles {
  my $self = shift;
  my $ARGS = $self->{ARGS};
  my $memberid = $ARGS->{memberid};

  my $c = $ARGS->{credit};

  return $self->do_sql( 
"INSERT INTO family_leftright (memberid, level, numleft)
SELECT parent, level, $c FROM family WHERE child=? AND leg='L'
ON DUPLICATE KEY UPDATE numleft=numleft+$c", $memberid)
	|| $self->do_sql(
"UPDATE member
SET milel=milel+$c, countl=countl+1
WHERE memberid IN
(SELECT parent FROM family WHERE child=? AND leg='L')", $memberid)
	|| $self->do_sql(
"INSERT INTO family_leftright (memberid, level, numright)
SELECT parent, level, $c FROM family WHERE child=? AND leg='R'
ON DUPLICATE KEY UPDATE numright=numright+$c", $memberid)
	|| $self->do_sql(
"UPDATE member
SET miler=miler+$c, countr=countr+1
WHERE memberid IN
(SELECT parent FROM family WHERE child=? AND leg='R')", $memberid);
}

sub update_miles {
  my $self = shift;
  my $ARGS = $self->{ARGS};
  my $memberid = $ARGS->{memberid};

  my $c = $ARGS->{credit};
#  my $one = 0;
#  if ($ARGS->{cancelfirst}) {
#    $one = -1;
#  } elsif ($ARGS->{action} eq 'upgrade') {
#    $one = 1;
#  }

  return $self->do_sql( 
"UPDATE family_leftright INNER JOIN family
ON family_leftright.memberid=family.parent AND family_leftright.level=family.level
SET numleft=numleft+($c)
WHERE family.child=? AND leg='L'", $memberid)
	|| $self->do_sql(
    #"UPDATE member SET milel=milel+($c), countl=countl+($one)
"UPDATE member SET milel=milel+($c)
WHERE memberid IN
(SELECT parent FROM family WHERE child=? AND leg='L')", $memberid)
	|| $self->do_sql(
"UPDATE family_leftright INNER JOIN family
ON family_leftright.memberid=family.parent AND family_leftright.level=family.level
SET numright=numright+($c)
WHERE family.child=? AND leg='R'", $memberid)
	|| $self->do_sql(
    #"UPDATE member SET miler=miler+($c), countr=countr+($one)
"UPDATE member SET miler=miler+($c)
WHERE memberid IN
(SELECT parent FROM family WHERE child=? AND leg='R')", $memberid);
}

1;
