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
        podfile => $infile,
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

pass($0);
__END__
my $outfile = "cacheout.html";
my $cachefile = "pod2htmd.tmp";
my $tcachefile = "t/pod2htmd.tmp";
my ($cache, $podpath, $podroot);

unlink $cachefile, $tcachefile;
is(-f $cachefile, undef, "No cache file to start");
is(-f $tcachefile, undef, "No cache file to start");

# I.
# test podpath and podroot
$options = {
    podfile => $infile,
    outfile  => $outfile,
    podpath => "scooby:shaggy:fred:velma:daphne",
    podroot => $cwd,
};
$p2h = Pod::Html->new();
$p2h->process_options( $options );
$p2h->cleanup_elements();
$rv = $p2h->generate_pages_cache();
ok(defined($rv),
    "generate_pages_cache() returned defined value, indicating full run");

is(-f $cachefile, 1, "Cache created");
open($cache, '<', $cachefile) or die "Cannot open cache file: $!";
chomp($podpath = <$cache>);
chomp($podroot = <$cache>);
close $cache;
is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
is($podroot, "$cwd", "podroot");

# II.
# test cache contents
{
    my %pages = ();
    my %expected_pages = ();
    $options = {
        podfile => $infile,
        outfile  => $outfile,
        cachedir => 't',
        podpath => 't',
        htmldir => $cwd,
    };
    $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    my $ucachefile = $p2h->get('Dircache');
    ok( ! (-f $ucachefile), "'Dircache' set but file $ucachefile does not exist");
    $rv = $p2h->generate_pages_cache();
    ok(defined($rv),
        "generate_pages_cache() returned defined value, indicating full run");
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
    ok( (-f $ucachefile), "'Dircache' now set and file $ucachefile exists");

    # IIa.
    # Now that the cachefile exists, we'll conduct another run to exercise
    # other parts of the code.
    $rv = $p2h->generate_pages_cache();
    ok(! defined($rv),
        "generate_pages_cache() returned undefined value, indicating no need for full run");
}
# Cleanup
1 while unlink $outfile;
1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

########## Tests for verbose output ##########

is(-f $cachefile, undef, "No cache file to start");
is(-f $tcachefile, undef, "No cache file to start");

# III.
# test podpath and podroot
{
    $options = {
        podfile => $infile,
        outfile  => $outfile,
        podpath => "scooby:shaggy:fred:velma:daphne",
        podroot => $cwd,
        verbose => 1,
    };
    $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    {
        my ($stdout, $stderr);
        capture(
            sub { $rv = $p2h->generate_pages_cache(); },
            \$stdout,
            \$stderr,
        );
        ok(defined($rv),
            "generate_pages_cache() returned defined value, indicating full run");
        like($stderr, qr/caching directories for later use/s,
            "generate_pages_cache(): verbose: caching directories");
    }
    is(-f $cachefile, 1, "Cache created");
    open($cache, '<', $cachefile) or die "Cannot open cache file: $!";
    chomp($podpath = <$cache>);
    chomp($podroot = <$cache>);
    close $cache;
    is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
    is($podroot, "$cwd", "podroot");
}

# IV.
# test cache contents
{
    my %pages = ();
    my %expected_pages = ();

    $options = {
        podfile => $infile,
        outfile  => $outfile,
        cachedir => 't',
        podpath => 't',
        htmldir => $cwd,
        verbose => 1,
    };
    $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    {
        my ($stdout, $stderr);
        capture(
            sub { $rv = $p2h->generate_pages_cache(); },
            \$stdout,
            \$stderr,
        );
        ok(defined($rv),
            "generate_pages_cache() returned defined value, indicating full run");
        like($stderr, qr/caching directories for later use/s,
            "generate_pages_cache(): verbose: caching directories");
    }
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

    # IVa.
    # Now that the cachefile exists, we'll conduct another run to exercise
    # other parts of the code.
    {
        my ($stdout, $stderr);
        capture(
            sub { $rv = $p2h->generate_pages_cache(); },
            \$stdout,
            \$stderr,
        );
        ok(! defined($rv),
            "generate_pages_cache() returned undefined value, indicating no need for full run");
        like(
            $stderr,
            qr/scanning for directory cache/s,
            "got verbose output: scanning",
        );
        like(
            $stderr,
            qr/loading directory cache/s,
            "got verbose output: loading",
        );
    }
}

# Cleanup
1 while unlink $outfile;
1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

############################
$options = {
    podfile => $infile,
    outfile  => $outfile,
    podpath => "scooby:shaggy:fred:velma:daphne",
    podroot => "..",
};
$p2h = Pod::Html->new();
$p2h->process_options( $options );
$p2h->cleanup_elements();
$rv = $p2h->generate_pages_cache();
ok(defined($rv),
    "generate_pages_cache() returned defined value, indicating full run");
is(-f $cachefile, 1, "Cache created");
open($cache, '<', $cachefile) or die "Cannot open cache file: $!";
chomp($podpath = <$cache>);
chomp($podroot = <$cache>);
close $cache;
is($podpath, "scooby:shaggy:fred:velma:daphne", "podpath");
is($podroot, "..", "podroot");

# Cleanup
1 while unlink $outfile;
1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");
__END__
