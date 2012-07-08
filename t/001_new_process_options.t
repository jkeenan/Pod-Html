# -*- perl -*-
use strict;
use warnings;
use Pod::Html;
use Test::More qw(no_plan); # tests => 2;
use Data::Dumper;$Data::Dumper::Indent=1;

my ($p2h, $rv);
$p2h = Pod::Html->new();
ok($p2h, 'Pod::Html returned true value');
isa_ok($p2h, 'Pod::Html');

$rv = $p2h->process_options();
ok($rv, 'process_options() returned true with no argument');
#print STDERR Dumper $p2h;
like($p2h->get('Dircache'), qr/pod2htmd\.tmp/,
    "process_options() returned plausible value for 'Dircache'");

{
    $p2h = Pod::Html->new();
    eval { $rv = $p2h->process_options( [ 'alpha' => 'beta' ] ); };
    like($@, qr/process_options\(\) needs hashref/,
        "process_options: got expected 'die' message for wrong argument type");
}

