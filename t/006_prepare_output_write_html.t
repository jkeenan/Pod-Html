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
use IO::CaptureOutput qw( capture );

my ($options, $p2h, $rv);
my $cwd = Pod::Html::unixify(Cwd::cwd());
my $infile = "t/cache.pod";
my $outfile = "cacheout.html";
my $cachefile = "pod2htmd.tmp";
my $tcachefile = "t/pod2htmd.tmp";
my ($podpath, $podroot);

unlink $cachefile, $tcachefile;
is(-f $cachefile, undef, "No cache file to start");
is(-f $tcachefile, undef, "No cache file to start");

{
    $options = {
        infile => $infile,
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
    
    my $parser = $p2h->prepare_parser();
    ok($parser, "prepare_parser() returned true value");
    isa_ok($parser, 'Pod::Simple::XHTML');
    ok($p2h->prepare_html_components($parser),
        "prepare_html_components() returned true value");
    
    my $output = $p2h->prepare_output($parser);
    ok(defined $output, "prepare_output() returned defined value");

    my $rv = $p2h->write_html($output);
    ok($rv, "write_html() returned true value");
}

# Cleanup
1 while unlink $outfile;
1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");
__END__

