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
use Test::More qw(no_plan); # tests => 12;

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
    ok(! $self->get('htmldir'), "'htmldir' starts out empty");
    ok(! $self->get('splitpod'), "'splitpod' starts out empty");

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
    is($self->get('htmldir'), $arrays->[0],
        "'htmldir' verified as set by process_options");
    is($self->get('splitpod'), $arrays->[1],
        "'splitpod' verified as set by process_options");
    chdir $cwd or die "Unable to change back to start directory";
}

{
    $self = Pod::Html::Installhtml->new();
    isa_ok($self, "Pod::Html::Installhtml");
    ok(! $self->get('htmldir'), "'htmldir' starts out empty");
    ok(! $self->get('splitpod'), "'splitpod' starts out empty");

    my $tdir = tempdir( CLEANUP => 1 );
    chdir $tdir or die "Unable to change to tempdir";
    my $arrays = [ "$tdir/html", "$tdir/pod" ];
    ok( ! -d $arrays->[0], "'htmldir' does not yet exist" );
    $opts = {
        htmldir => $arrays->[0],
        splitpod => $arrays->[1],
    };
    $self->process_options( $opts );
    $self->cleanup_elements();
    is($self->get('htmldir'), $arrays->[0],
        "'htmldir' verified as set by process_options");
    is($self->get('splitpod'), $arrays->[1],
        "'splitpod' verified as set by process_options");
    ok( -d $arrays->[0], "'htmldir' was created" );
    chdir $cwd or die "Unable to change back to start directory";
}

{
    $self = Pod::Html::Installhtml->new();
    isa_ok($self, "Pod::Html::Installhtml");
    ok(! $self->get('htmldir'), "'htmldir' starts out empty");

    $opts = {
        htmldir => $tmphtmldir,
    };
    $self->process_options( $opts );
    $self->cleanup_elements();
    is($self->get('htmldir'), $tmphtmldir,
        "'htmldir' verified as set by process_options");
    chdir $cwd or die "Unable to change back to start directory";
}

# cleanup

1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

File::Path::rmtree( $tmphtmldir, 0 );
ok(! (-d $tmphtmldir), "No temp html directory to start");
