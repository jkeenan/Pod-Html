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
use Data::Dumper;$Data::Dumper::Indent = 1;
use File::Path qw( mkpath rmtree );
use File::Temp qw( tempdir );
use Pod::Html::Installhtml;
use Pod::Html::Auxiliary qw( unixify );
use Scalar::Util qw( reftype );
use Test::More qw(no_plan); # tests => 12;
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
my ($self, $podpath, $podroot, $splitpod, $splitdirs, $splithead, $splititem, $ignore);
my ($opts);

{
    $self = Pod::Html::Installhtml->new();
    isa_ok($self, "Pod::Html::Installhtml");

    my $opt_podroot = "./xt";
    my $opt_podpath = "split";
    my @opt_splithead = ( "split/splithead1", "split/splithead2" );
    $opts = {
      podroot => $opt_podroot,
      podpath => $opt_podpath,
      splithead => join(',' => @opt_splithead),
      recurse => 1,
      htmldir => "$cwd/tmphtml",
      verbose => 0,
    };
    $self->process_options( $opts );
    $self->cleanup_elements();
    $self->split_on_head();

    $podpath = $self->get('podpath');
    is(reftype($podpath), 'ARRAY', "'podpath' is array reference");
    is($podpath->[0], $opt_podpath, "'split' is first directory in 'podpath'");
    $podroot = $self->get('podroot');
    is($podroot, $opt_podroot, "'podroot' set as expected");
    $splitpod = $self->get('splitpod');
    is($splitpod, "$podroot/pod", "'splitpod' set as expected");
    $splitdirs = $self->get('splitdirs');
    is(reftype($splitdirs), 'ARRAY', "'splitdirs' is array reference");
    is(scalar(@$splitdirs), 2, "'splitdirs' has 2 elements");
    is(reftype($splitdirs->[0]), 'ARRAY',
        "'splitdirs' first element is array reference");
    is($splitdirs->[0]->[0], "$podroot/$opt_splithead[0]",
        "First directory in 'splitdirs' is set as expected");
    $splithead = $self->get('splithead');
    is(reftype($splithead), 'ARRAY', "'splithead' is array reference");
    is(scalar(@$splithead), 2, "'splithead' has 2 elements");
    is($splithead->[0], $opt_splithead[0],
        "First file in 'splithead' is set as expected");
    $ignore = $self->get('ignore');
    is(reftype($ignore), 'ARRAY', "'ignore' is array reference");
    is(scalar(@$ignore), 2, "'ignore' has 2 elements");
    is($ignore->[0], "$podroot/$opt_splithead[0].pod",
        "First file in 'ignore' is set as expected");
}

# test verbose output

{
    $self = Pod::Html::Installhtml->new();
    isa_ok($self, "Pod::Html::Installhtml");

    my $opt_podroot = "./xt";
    my $opt_podpath = "split";
    my @opt_splithead = ( "split/splithead1", "split/splithead2" );
    $opts = {
      podroot => $opt_podroot,
      podpath => $opt_podpath,
      splithead => join(',' => @opt_splithead),
      recurse => 1,
      htmldir => "$cwd/tmphtml",
      verbose => 1,
    };
    $self->process_options( $opts );
    $self->cleanup_elements();
    {
        my  ($stdout, $stderr);
        capture(
            sub { $self->split_on_head(); },
            \$stdout,
            \$stderr,
        );
        like($stdout, qr/splitting files by head/s,
            "split_on_head(): got expected verbose output");
    }
}

{
    $self = Pod::Html::Installhtml->new();
    isa_ok($self, "Pod::Html::Installhtml");

    my $opt_podroot = "./xt";
    my $opt_podpath = "split";
    my @opt_splithead = ( "split/splithead1", "split/splithead2" );
    $opts = {
      podroot => $opt_podroot,
      podpath => $opt_podpath,
#      splithead => join(',' => @opt_splithead),
      recurse => 1,
      htmldir => "$cwd/tmphtml",
      verbose => 1,
    };
    $self->process_options( $opts );
    $self->cleanup_elements();
    {
        my  ($stdout, $stderr);
        capture(
            sub { $self->split_on_head(); },
            \$stdout,
            \$stderr,
        );
        ok( ! $stdout, "No verbose output, given no elements in splithead");
    }
}

# cleanup

1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

# Compensate for the lack of cleanup described in the TODO block above.
File::Path::rmtree( "$cwd/xt/split/splithead1", 0 );
File::Path::rmtree( "$cwd/xt/split/splithead2", 0 );

File::Path::rmtree( $tmphtmldir, 0 );
ok(! (-d $tmphtmldir), "No temp html directory to start");
