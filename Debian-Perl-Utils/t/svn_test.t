#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Debian::Perl::Utils;

BEGIN {
  use_ok('Debian::Perl::Utils');
}

my %svn_repo = ();
my $svn_ref = \%svn_repo;
my $svn = Debian::Perl::Utils->new($svn_ref);
isa_ok($svn, "Debian::Perl::Utils");

##
## This is hard coded! You'll want to put your own SVN dir here.
##
#$svn->_svn_check("/home/jeremiah/code/perl/pkg-perl/libnet-dhcp-perl");
#diag($svn->{'repo'});

