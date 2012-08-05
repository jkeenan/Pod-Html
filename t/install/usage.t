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
use Test::More tests => 10;
use IO::CaptureOutput qw( capture );

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

{
    my (@cmdargs, $cmd, $stdout, $stderr, $rv);
    @cmdargs = (
        $^X,
        "$cwd/bin/installhtml",
    );
    $cmd = join(' ' => @cmdargs);

    capture(
        sub { eval { $rv = system($cmd); }; },
        \$stdout,
        \$stderr,
    );
    like( $stderr, qr/Usage/s,
        "Got usage statement when bin/installhtml was provided with zero argument" );
    isnt( $rv, 0, "bin/installhtml did not return 0 for success" );
}

{
    my (@cmdargs, $cmd, $stdout, $stderr, $rv);
    @cmdargs = (
        $^X,
        "$cwd/bin/installhtml",
        "--help",
    );
    $cmd = join(' ' => @cmdargs);

    capture(
        sub { eval { $rv = system($cmd); }; },
        \$stdout,
        \$stderr,
    );
    like( $stderr, qr/Usage/s,
        "Got usage statement when '--help' passed on command-line" );
    isnt( $rv, 0, "bin/installhtml did not return 0 for success" );
}
# cleanup

1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

File::Path::rmtree( $tmphtmldir, 0 );
ok(! (-d $tmphtmldir), "No temp html directory to start");
