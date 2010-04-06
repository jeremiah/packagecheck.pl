#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Debian::Perl::Utils' ) || print "Bail out!
";
}

diag( "Testing Debian::Perl::Utils $Debian::Perl::Utils::VERSION, Perl $], $^X" );
