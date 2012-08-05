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
use File::Path qw( mkpath rmtree );
use File::Temp qw( tempdir );
use Pod::Html::Installhtml;
use Pod::Html::Auxiliary qw( unixify );
use Scalar::Util qw( reftype );
use Test::More qw(no_plan); # tests => 24;

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
my ($self, $podpath, $podroot, $splithead, $splititem, $ignore);
my ($opts);

{
    $self = Pod::Html::Installhtml->new();
    isa_ok($self, "Pod::Html::Installhtml");

    my $tdir = tempdir( CLEANUP => 1 );
    chdir $tdir or die "Unable to change to tempdir";
    my $arrays = [ "$tdir/html", "$tdir/pod" ];
    mkpath( $arrays, 0, 0755);
    $opts = {
        htmldir => $arrays->[0],
        splitpod => $arrays->[1],
    };
    $self->process_options( $opts );
    $self->cleanup_elements();
    ok($self->basic_installation(),
        "'basic_installation() returned true value");

    chdir $cwd or die "Unable to change back to start directory";
}


# cleanup

1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

File::Path::rmtree( $tmphtmldir, 0 );
ok(! (-d $tmphtmldir), "No temp html directory to start");
