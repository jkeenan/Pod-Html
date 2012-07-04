# -*- perl -*-
use strict;
use Pod::Html::Auxiliary qw( parse_command_line );
use Test::More tests => 2;

my %globals = ();
%globals = parse_command_line(%globals);
ok( exists $globals{Dircache},
   "With no options, 'Dircache' is only element guaranteed to exist" );
like( $globals{Dircache}, qr/pod2htmd\.tmp/,
    "Got expected value for 'Dircache'" );


