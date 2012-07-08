# -*- perl -*-
use strict;
use Pod::Html::Auxiliary qw( parse_command_line );
use Test::More tests => 1;

my $options = parse_command_line();
is( ref($options), 'HASH',
    "parse_command_line() returned hashref" );
