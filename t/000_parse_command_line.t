# -*- perl -*-
use strict;
use Pod::Html::Auxiliary qw( parse_command_line );
use Test::More tests => 1;

my $opts = parse_command_line();
is( ref($opts), 'HASH',
    "parse_command_line() returned hashref" );
