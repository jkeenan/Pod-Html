# -*- perl -*-
use strict;
use warnings;
use Pod::Html;
use Pod::Html::Auxiliary qw( unixify );
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
ok(! defined $p2h->get(), "get() was not provided with an argument");
ok(! defined $p2h->get('foobar'),
    "No 'foobar' element in object");
ok(! defined $p2h->get('Saved_Cache_Key'),
    "At this point, 'Saved_Cache_Key' is correctly detected as not defined");

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

{
    local $@;
    $p2h = Pod::Html->new();
    ok($p2h, 'Pod::Html returned true value');
    $rv = $p2h->process_options( {
        Htmlroot => '/some/path', 
        Htmldir  => '/some/other/path', 
     } );
    ok($rv, "process_options() returned true value");
    eval { $rv = $p2h->cleanup_elements(); };
    like($@, qr/htmlroot and htmldir cannot both be set to true values/s,
        "cleanup_elements() detected assignments of true value to both htmlroot and htmldir");
}

{
    local $@;
    $p2h = Pod::Html->new();
    ok($p2h, 'Pod::Html returned true value');
    $rv = $p2h->process_options( {
        Htmlroot => '/', # Internally reassigned to empty string
        Htmldir  => '/some/other/path', 
     } );
    ok($rv, "process_options() returned true value");
    eval { $rv = $p2h->cleanup_elements(); };
    ok(!$@, "Okay to have false Htmlroot and true Htmldir");
}

{
    local $@;
    $p2h = Pod::Html->new();
    ok($p2h, 'Pod::Html returned true value');
    $rv = $p2h->process_options( {
        Htmlroot => '/some/path', 
        Htmldir  => undef, 
     } );
    ok($rv, "process_options() returned true value");
    eval { $rv = $p2h->cleanup_elements(); };
    ok(!$@, "Okay to have defined Htmlroot and false Htmldir");
}

{
    local $@;
    $p2h = Pod::Html->new();
    ok($p2h, 'Pod::Html returned true value');
    $rv = $p2h->process_options( {
        Htmlroot => '/', # Internally reassigned to empty string
        Htmldir  => '/some/other/spring', 
        Htmlfile => '/some/other/spring',
     } );
    ok($rv, "process_options() returned true value");
    eval { $rv = $p2h->cleanup_elements(); };
    ok(!$@, "Okay to have false Htmlroot and true Htmldir");
    is(
        $p2h->get('Htmlfileurl'),
        unixify($p2h->get('Htmlfile')),
        "Got expected value for Htmlfileurl"
    );
}

__END__
#print STDERR Dumper $p2h;
