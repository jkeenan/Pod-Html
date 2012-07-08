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

$rv = $p2h->process_options( {
    verbose => 1,
    flush => 1, 
 } );
ok($rv, "process_options() returned true value");

{
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = $_[0]; };
    $p2h->cleanup_elements();
    like($warning, qr/Flushing directory caches/,
        "process_options(): got expected warning with 'flush' and 'verbose'");
}

$p2h = Pod::Html->new();
ok($p2h, 'Pod::Html returned true value');
$rv = $p2h->process_options( {
    flush => 1, 
 } );
ok($rv, "process_options() returned true value");
{
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = $_[0]; };
    $p2h->cleanup_elements();
    unlike($warning, qr/Flushing directory caches/,
        "process_options(): as expected, no warning with only 'flush'");
}

$p2h = Pod::Html->new();
ok($p2h, 'Pod::Html returned true value');
$rv = $p2h->process_options( {
    verbose => 1, 
 } );
ok($rv, "process_options() returned true value");
{
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = $_[0]; };
    $p2h->cleanup_elements();
    unlike($warning, qr/Flushing directory caches/,
        "process_options(): as expected, no warning with only 'verbose'");
}

