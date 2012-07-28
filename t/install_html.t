#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    die "Run me from outside the t/ directory, please" unless -d 't';
}

# test 'bin/installhtml'
# This file tests the program 'bin/installhtml', which invokes
# Pod::Html::pod2html but prepares for that invocation in a way which differs
# significantly from the 'pod2html' utility.

use strict;
use Cwd;
use File::Path qw( rmtree );
use Pod::Html ();
use Test::More tests => 12;

my $cwd = Pod::Html::_unixify(Cwd::cwd());
my $tmphtmldir = "$cwd/tmphtml";

# preparation

File::Path::rmtree( $tmphtmldir, 0 );
ok(! (-d $tmphtmldir), "No temp html directory to start");

my $cachefile = "pod2htmd.tmp";
my $tcachefile = "t/pod2htmd.tmp";

unlink $cachefile, $tcachefile;
is(-f $cachefile, undef, "No cache file to start");
is(-f $tcachefile, undef, "No cache file to start");

# actual tests

my @cmdargs = (
    $^X,
    "$cwd/bin/installhtml",
    "--podroot=./xt",
    "--podpath=lib:pod",
    "--recurse",
    "--htmldir=$cwd/tmphtml",
);
my $cmd = join(' ' => @cmdargs);
#print STDERR "command: $cmd\n";
system($cmd) and die "Unable to run bin/installhtml: $!";
my $expected_htmldir = "$cwd/tmphtml";
foreach my $dir ( "$expected_htmldir/lib/Pod", "$expected_htmldir/pod" ) {
    ok( -d $dir, "Got expected directory $dir for html");
}
foreach my $file (
    "$expected_htmldir/lib/Pod/Html.html",
    "$expected_htmldir/pod/cache.html",
    "$expected_htmldir/pod/feature.html",
    "$expected_htmldir/pod/htmlview.html",
 ) {
    ok( -f $file, "Got expected file $file for html");
}

# cleanup

1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

File::Path::rmtree( $tmphtmldir, 0 );
ok(! (-d $tmphtmldir), "No temp html directory to start");
