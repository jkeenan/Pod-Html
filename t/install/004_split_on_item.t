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
use Test::More qw(no_plan); # tests => 25;
use IO::CaptureOutput qw( capture );
my $cwd = unixify(Cwd::cwd()); my $tmphtmldir = "$cwd/tmphtml"; # preparation 
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
    my @opt_splititem = ( "split/splititem1", "split/splititem2" );
    $opts = {
      podroot => $opt_podroot,
      podpath => $opt_podpath,
      htmldir => "$cwd/tmphtml",
      splithead => join(',' => @opt_splithead),
      splititem => join(',' => @opt_splititem),
      recurse => 1,
      verbose => 0,
    };
    $self->process_options( $opts );
    $self->cleanup_elements();
    $self->split_on_head();
    eval { $self->split_on_item(); };
    my $splitter = "$opt_podroot/pod/splitpod";
    like($@, qr/$splitter not found/s,
        "split_on_item(): failed as expected due to lack of '--splitpod'");
    # Following chdir is needed because split_on_item() chdirs internally.
    chdir $cwd;
}

# test verbose output

{
    $self = Pod::Html::Installhtml->new();
    isa_ok($self, "Pod::Html::Installhtml");

    my $opt_podroot = "./xt";
    my $opt_podpath = "split";
    my @opt_splithead = ( "split/splithead1", "split/splithead2" );
    my @opt_splititem = ( "split/splititem1", "split/splititem2" );
    $opts = {
      podroot => $opt_podroot,
      podpath => $opt_podpath,
      htmldir => "$cwd/tmphtml",
      splithead => join(',' => @opt_splithead),
      splititem => join(',' => @opt_splititem),
      recurse => 1,
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

        capture(
            sub { eval { $self->split_on_item(); }; },
            \$stdout,
            \$stderr,
        );
        my $splitter = "$opt_podroot/pod/splitpod";
        like($@, qr/$splitter not found/s,
            "split_on_item(): failed as expected due to lack of '--splitpod'");
        like($stdout, qr/splitting files by item/s,
            "split_on_item(): got expected verbose output");
    }
    # Following chdir is needed because split_on_item() chdirs internally.
    chdir $cwd;
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
