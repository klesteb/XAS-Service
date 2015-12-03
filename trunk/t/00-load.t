#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XAS::xxxx' ) || print "Bail out!\n";
}

diag( "Testing XAS::xxxx $XAS::xxxx::VERSION, Perl $], $^X" );
