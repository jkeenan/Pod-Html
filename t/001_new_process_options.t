# -*- perl -*-
use strict;
use warnings;
use Pod::Html;
use Test::More qw(no_plan); # tests => 2;
use Data::Dumper;$Data::Dumper::Indent=1;
#print STDERR Dumper $p2h;
use IO::CaptureOutput qw( capture );

my ($p2h, $rv);
{
    $p2h = Pod::Html->new();
    ok($p2h, 'Pod::Html returned true value');
    isa_ok($p2h, 'Pod::Html');
    
    $rv = $p2h->process_options();
    ok($rv, 'process_options() returned true with no argument');
    like($p2h->get('Dircache'), qr/pod2htmd\.tmp/,
        "process_options() returned plausible value for 'Dircache'");
}

{
    $p2h = Pod::Html->new();
    eval { $rv = $p2h->process_options( [ 'alpha' => 'beta' ] ); };
    like($@, qr/process_options\(\) needs hashref/,
        "process_options: got expected 'die' message for wrong argument type");
}

{
    $p2h = Pod::Html->new();
    {
        my ($stdout, $stderr);
        capture(
            sub { $rv = $p2h->process_options( { 'libpods' => '/alpha/beta' } ); },
            \$stdout,
            \$stderr,
        );
        like(
            $stderr,
            qr/--libpods is no longer supported/,
            "process_options(): got deprecation warning for 'libpods'",
        );
    }
}

# Sanity checks for options not heretofore tested
{
    $p2h = Pod::Html->new();
    ok($p2h, 'Pod::Html returned true value');
    isa_ok($p2h, 'Pod::Html');
    
    my $infile = 't/cache.t';
    $rv = $p2h->process_options( {
        backlink => 1,
        # css => 'path/to/stylesheet.css',
        header => 1,
        'index' => 0,
        infile => $infile,
        # outfile => 'path/to/htmlfile',
        poderrors => 0,
        quiet => 1,
        recurse => 1,
        title => 1,
    } );
    ok($rv, 'process_options() returned true with multiple arguments');
    like($p2h->get('Dircache'), qr/pod2htmd\.tmp/,
        "process_options() returned plausible value for 'Dircache'");
    ok($p2h->get('Backlink'), "backlinks selected");
    ok($p2h->get('Header'), "header selected");
    ok(! $p2h->get('Index'), "index not selected");
    is($p2h->get('Podfile'), $infile,
        "input file $infile correctly identified");
    ok(! $p2h->get('Poderrors'), "poderrors not selected");
    ok($p2h->get('Quiet'), "quiet selected");
    ok($p2h->get('Recurse'), "recurse selected");
    ok($p2h->get('Title'), "title selected");
}
