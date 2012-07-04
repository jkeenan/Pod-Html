# -*- perl -*-
use strict;
use Cwd;
use File::Spec;
use File::Spec::Unix;
use Pod::Html::Auxiliary qw( unixify );
use Test::More qw(no_plan); # tests => 1;

my $cwd = cwd();
my @curdirs = File::Spec::Unix::curdir();
my ($full_path, $rv);

is(unixify($full_path), '', "Got expected empty string");

$full_path = '/';
is(unixify($full_path), $full_path, "Got expected '/'");

SKIP: {
    skip "Test does not apply on MSWin32 or VMS",
    2 if ($^O eq 'VMS' or $^O eq 'MSWin32');
    $full_path = "$cwd/$0";
    is(unixify($full_path), $full_path, "Got expected full path");

    $full_path = 'foobar';
    is(unixify($full_path), $full_path, "Got expected file");
}
