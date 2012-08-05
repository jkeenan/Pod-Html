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
use Pod::Html::Auxiliary qw( unixify );
use Test::More tests => 21;

my $cwd = unixify(Cwd::cwd());
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
    "$expected_htmldir/split/splithead1.html",
    "$expected_htmldir/split/splithead1/feature_a.html",
    "$expected_htmldir/split/splithead1/feature_b.html",
    "$expected_htmldir/split/splithead2.html",
    "$expected_htmldir/split/splithead2/feature_c.html",
    "$expected_htmldir/split/splithead2/feature_d.html",
 ) {
    ok( -f $file, "Got expected file $file for html");
}

# cleanup

TODO: {
    local $TODO = '--splithead failing to clean up intermediate files';

    foreach my $dir (
        "$cwd/xt/split/splithead1",
        "$cwd/xt/split/splithead2",
    ) {
        ok( ! (-d $dir), "Intermediate directory cleaned up automatically" );
    }
    foreach my $file (
        "$cwd/xt/split/splithead1/feature_a.pod",
        "$cwd/xt/split/splithead1/feature_b.pod",
        "$cwd/xt/split/splithead2/feature_c.pod",
        "$cwd/xt/split/splithead2/feature_d.pod",
    ) {
        ok( ! (-f $file), "Intermediate file cleaned up automatically" );
    }

}

1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

# Compensate for the lack of cleanup described in the TODO block above.
File::Path::rmtree( "$cwd/xt/split/splithead1", 0 );
File::Path::rmtree( "$cwd/xt/split/splithead2", 0 );

File::Path::rmtree( $tmphtmldir, 0 );
ok(! (-d $tmphtmldir), "No temp html directory to start");
