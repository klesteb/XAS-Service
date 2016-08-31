#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
} else {
    plan tests => 10;
}

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

TODO: {
  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/XAS/Service.pm');
  module_boilerplate_ok('lib/XAS/Apps/Service/Testd.pm');
  module_boilerplate_ok('lib/XAS/Docs/Service/Installation.pm');
  module_boilerplate_ok('lib/XAS/Service/CheckParameters.pm');
  module_boilerplate_ok('lib/XAS/Service/Profiles.pm');
  module_boilerplate_ok('lib/XAS/Service/Resource.pm');
  module_boilerplate_ok('lib/XAS/Service/Search.pm');
  module_boilerplate_ok('lib/XAS/Service/Server.pm');
  module_boilerplate_ok('lib/XAS/Service/Profiles/Search.pm');

}

