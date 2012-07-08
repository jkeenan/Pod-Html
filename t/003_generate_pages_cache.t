#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    die "Run me from outside the t/ directory, please" unless -d 't';
}

# test the directory cache
# XXX test --flush and %Pages being loaded/used for cross references

use strict;
use Cwd;
use Pod::Html;
use Pod::Html::Auxiliary qw(
    parse_command_line
    unixify
);
use Data::Dumper;
use Test::More qw(no_plan); # tests => 10;

my ($options, $p2h);
my $cwd = Pod::Html::unixify(Cwd::cwd());
my $infile = "t/cache.pod";
my $outfile = "cacheout.html";
my $cachefile = "pod2htmd.tmp";
my $tcachefile = "t/pod2htmd.tmp";
my %pages;
my %expected_pages;
my ($cache, $podpath, $podroot);

unlink $cachefile, $tcachefile;
is(-f $cachefile, undef, "No cache file to start");
is(-f $tcachefile, undef, "No cache file to start");

# test podpath and podroot
$options = {
    Podfile => unixify($infile),
    Htmlfile => unixify($outfile),
    Podpath => [ split ':', "scooby:shaggy:fred:velma:daphne" ],
    Podroot => $cwd,
};
$p2h = Pod::Html->new();
$p2h->process_options( $options );
$p2h->cleanup_elements();
$p2h->generate_pages_cache();

is(-f $cachefile, 1, "Cache created");
open($cache, '<', $cachefile) or die "Cannot open cache file: $!";
chomp($podpath = <$cache>);
chomp($podroot = <$cache>);
close $cache;
is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
is($podroot, "$cwd", "podroot");

## test cache contents
$options = {
    Podfile => unixify($infile),
    Htmlfile => unixify($outfile),
    Cachedir => unixify('t'),
    Podpath => [ split ':', "t" ],
    Htmldir => unixify($cwd),
};
$p2h = Pod::Html->new();
$p2h->process_options( $options );
$p2h->cleanup_elements();
$p2h->generate_pages_cache();
is(-f $tcachefile, 1, "Cache created");
open($cache, '<', $tcachefile) or die "Cannot open cache file: $!";
chomp($podpath = <$cache>);
chomp($podroot = <$cache>);
is($podpath, "t", "podpath");
%pages = ();
while (<$cache>) {
    /(.*?) (.*)$/;
    $pages{$1} = $2;
}
chdir("t");
%expected_pages = 
    # chop off the .pod and set the path
    map { my $f = substr($_, 0, -4); $f => "t/$f" }
    <*.pod>;
chdir($cwd);
is_deeply(\%pages, \%expected_pages, "cache contents");
close $cache;
%pages = ();
%expected_pages = ();

# Tests for verbose output
{
    my $warn;
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    
    # test podpath and podroot
    $options = {
        Podfile => unixify($infile),
        Htmlfile => unixify($outfile),
        Podpath => [ split ':', "scooby:shaggy:fred:velma:daphne" ],
        Podroot => $cwd,
        Verbose => 1,
    };
    $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    $p2h->generate_pages_cache();
    is(-f $cachefile, 1, "Cache created");
    open($cache, '<', $cachefile) or die "Cannot open cache file: $!";
    chomp($podpath = <$cache>);
    chomp($podroot = <$cache>);
    close $cache;
    is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
    is($podroot, "$cwd", "podroot");
    like(
        $warn,
        qr/scanning for directory cache/s,
        "got verbose output: scanning",
    );
    like(
        $warn,
        qr/loading directory cache/s,
        "got verbose output: loading",
    );
}
%pages = ();
%expected_pages = ();

# test cache contents
{
    my $warn;
    local $SIG{__WARN__} = sub { $warn .= $_[0] };

    $options = {
        Podfile => unixify($infile),
        Htmlfile => unixify($outfile),
        Cachedir => unixify('t'),
        Podpath => [ split ':', "t" ],
        Htmldir => unixify($cwd),
        Verbose => 1,
    };
    $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    $p2h->generate_pages_cache();
    is(-f $tcachefile, 1, "Cache created");
    open($cache, '<', $tcachefile) or die "Cannot open cache file: $!";
    chomp($podpath = <$cache>);
    chomp($podroot = <$cache>);
    is($podpath, "t", "podpath");
    %pages = ();
    while (<$cache>) {
        /(.*?) (.*)$/;
        $pages{$1} = $2;
    }
    chdir("t");
    %expected_pages = 
        # chop off the .pod and set the path
        map { my $f = substr($_, 0, -4); $f => "t/$f" }
        <*.pod>;
    chdir($cwd);
    is_deeply(\%pages, \%expected_pages, "cache contents");
    close $cache;
    like(
        $warn,
        qr/scanning for directory cache/s,
        "got verbose output: scanning",
    );
    like(
        $warn,
        qr/loading directory cache/s,
        "got verbose output: loading",
    );
}
%pages = ();
%expected_pages = ();

# Cleanup

1 while unlink $outfile;
1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");
