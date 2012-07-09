# -*- perl -*-
use strict;
use Pod::Html::Auxiliary qw( parse_command_line );
use Test::More tests => 15;

my $opts = parse_command_line();
is( ref($opts), 'HASH',
    "parse_command_line() returned hashref" );

my @no_able_switches = qw(
  backlink
  header
  index
  poderrors
  quiet
  recurse
  verbose
);
{
    local @ARGV = map { '--' . $_ } @no_able_switches;
    $opts = parse_command_line();
    foreach my $sw (@no_able_switches) {
      ok($opts->{$sw}, "$sw set true as expected");
    }
}

{
    local @ARGV = map { '--no' . $_ } @no_able_switches;
    $opts = parse_command_line();
    foreach my $sw (@no_able_switches) {
      ok(! $opts->{$sw}, "$sw set false as expected");
    }
}
