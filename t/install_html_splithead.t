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
use Test::More qw(no_plan); # tests => 12;

my $cwd = Pod::Html::Auxiliary::unixify(Cwd::cwd());
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
    "--podpath=split",
    "--splithead=split/splithead1,split/splithead2",
    "--recurse",
    "--htmldir=$cwd/tmphtml",
#    "--verbose",
);
my $cmd = join(' ' => @cmdargs);
#print STDERR "command: $cmd\n";
system($cmd) and die "Unable to run bin/installhtml: $!";
my $expected_htmldir = "$cwd/tmphtml";
foreach my $dir (
    "$expected_htmldir/split",
    "$expected_htmldir/split/splithead1",
    "$expected_htmldir/split/splithead2",
) {
    ok( -d $dir, "Got expected directory $dir for html");
}
foreach my $file (
    "$expected_htmldir/split/splithead1/feature_a.html",
    "$expected_htmldir/split/splithead1/feature_b.html",
    "$expected_htmldir/split/splithead2/feature_c.html",
    "$expected_htmldir/split/splithead2/feature_d.html",
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
