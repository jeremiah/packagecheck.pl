#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Debian::Perl::Utils;

BEGIN {
  use_ok('Debian::Control');
}

# Warning: hard coded
my $control_file = "/home/jeremiah/libacme-bleach-perl/debian/control";
my $ctrl = Debian::Control->new();
isa_ok($ctrl, "Debian::Control");
$ctrl->read($control_file);
diag($ctrl->source->Homepage);

