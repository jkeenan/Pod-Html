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
use Test::More tests =>  8;
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
      htmldir => "$cwd/tmphtml",
      splithead => join(',' => @opt_splithead),
      recurse => 1,
      verbose => 0,
    };
    $self->process_options( $opts );
    $self->cleanup_elements();
    $self->split_on_head();
    $self->basic_installation();
    # create_all_indices() cannot be meaningfully tested until we can figure
    # out how to get split_on_item() to complete successfully.  That's because
    # create_all_indices() has nothing to do unless @{$self->{splititem}} has
    # non-zero elements.
    my $rv = $self->create_all_indices();
    # Hence, the following test is only provisionally meaningful:
    is($rv, 0, "create_all_indices(): nothing to do");
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
