#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    die "Run me from outside the t/ directory, please" unless -d 't';
}

# test the directory cache
# XXX test --flush and %Pages being loaded/used for cross references

use strict;
use Carp;
use Cwd;
use File::Copy;
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use Pod::Html;
use Pod::Html::Auxiliary qw(
    parse_command_line
    unixify
);
use Data::Dumper;
use Test::More qw(no_plan); # tests => 10;
use IO::CaptureOutput qw( capture );

my ($options, $p2h, $rv);
my $cwd = Pod::Html::unixify(Cwd::cwd());
my $source_infile = "t/cache.pod";

{
    my $tdir = tempdir( CLEANUP => 1 );
    make_path("$tdir/alpha", "$tdir/beta", "$tdir/gamma", "$tdir/t", {
        verbose => 0,
        mode => 0755,
    });
    my $infile = "$tdir/alpha/cache.pod";
    my $outfile ="cacheout.html",
    copy $source_infile => $infile
        or croak "Unable to copy $infile";
    chdir "$tdir/alpha" or croak "Unable to change to $tdir/alpha";
    my $podroot_set = "..";
    my $podpath_set = join(':' => qw( alpha beta gamma ));

    my $cachefile = "pod2htmd.tmp";
    unlink $cachefile;
    is(-f $cachefile, undef, "No cache file to start");
    my %pages = ();
    my %expected_pages = ();
    $options = {
        infile => $infile,
        outfile => $outfile,
        podroot => $podroot_set,
        podpath => $podpath_set,
        htmldir => "$tdir/t",
    };
    $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    $rv = $p2h->generate_pages_cache();
    ok(defined($rv),
        "generate_pages_cache() returned defined value, indicating full run");
    
    is(-f $cachefile, 1, "Cache created");
    my ($podpath, $podroot);
    open my $CACHE, '<', $cachefile or croak "Cannot open cache file: $!";
    chomp($podpath = <$CACHE>);
    chomp($podroot = <$CACHE>);
    close $CACHE;
    is($podpath, $podpath_set, "podpath is $podpath_set");
    is($podroot, $podroot_set, "podroot is $podroot_set");
    chdir $cwd or croak "Unable to change back to $cwd";

    1 while unlink $outfile;
    1 while unlink $cachefile;
    is(-f $cachefile, undef, "No cache file to end");
}

