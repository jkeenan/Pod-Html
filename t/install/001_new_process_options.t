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
use File::Path qw( rmtree );
use Pod::Html::Installhtml;
use Pod::Html::Auxiliary qw( unixify );
use Scalar::Util qw( reftype );
use Test::More tests => 28;

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
my ($self, $podpath, $podroot, $splithead, $splititem, $ignore);
my (@opts_podpaths, @opts_splitheads, @opts_splititems, @opts_ignores, $opts);

$self = Pod::Html::Installhtml->new();
ok($self, "Pod::Html::Installhtml->new() returned true value");
isa_ok($self, "Pod::Html::Installhtml");
$podpath = $self->get('podpath');
is(reftype($podpath), 'ARRAY', "podpath is an array ref");
is($podpath->[0], '.', "podpath contains a single element: '.'");
$podroot = $self->get('podroot');
is($podroot, '.', "podroot is '.'");
$splithead = $self->get('splithead');
is(reftype($splithead), 'ARRAY', "splithead is an array ref");
is(scalar(@$splithead), 0, "splithead array is empty");
$splititem = $self->get('splititem');
is(reftype($splititem), 'ARRAY', "splititem is an array ref");
is(scalar(@$splititem), 0, "splititem array is empty");
$ignore = $self->get('ignore');
ok(! defined $ignore, "No ignored directories defined yet");

@opts_podpaths =qw ( alpha beta gamma );
@opts_splitheads = ( "alpha/delta", "beta/epsilon", "gamma/zeta" );
@opts_splititems = ( "alpha/eta", "beta/theta", "gamma/iota" );
@opts_ignores = ( "foo/file", "bar/baz" );
$opts = {
    podpath => join(':' => @opts_podpaths),
    splithead => join(',' => @opts_splitheads),
    splititem => join(',' => @opts_splititems),
    ignore => join(',' => @opts_ignores),
};
$self->process_options( $opts );
is_deeply($self->get('podpath'), [ @opts_podpaths ],
    "Got expected podpath directories");
is_deeply($self->get('splithead'), [ @opts_splitheads ],
    "Got expected splithead files");
is_deeply($self->get('splititem'), [ @opts_splititems ],
    "Got expected splititem files");
is_deeply(
    $self->get('ignore'),
    [ map { $self->get('podroot') . "/$_" } @opts_ignores ],
    "Got expected ignored files");

#####

$self = Pod::Html::Installhtml->new();
ok($self, "Pod::Html::Installhtml->new() returned true value");
isa_ok($self, "Pod::Html::Installhtml");
$podpath = $self->get('podpath');
is(reftype($podpath), 'ARRAY', "podpath is an array ref");
is($podpath->[0], '.', "podpath contains a single element: '.'");
# Test case where 'podpath' is undefined, hence default not overridden
$opts = { podpath => undef }; 
$self->process_options( $opts );
$podpath = $self->get('podpath');
is(reftype($podpath), 'ARRAY', "podpath still is an array ref");
is($podpath->[0], '.', "podpath still contains a single element: '.'");

{
    $self = Pod::Html::Installhtml->new();
    isa_ok($self, "Pod::Html::Installhtml");

    $opts = { podpath => '', };
    eval { $self->process_options( $opts ); };
    like($@, qr/'podpath' option, if used, must have non-zero number/,
        "Got expected die message for lack of content in 'podpath'");
}
# cleanup

1 while unlink $cachefile;
1 while unlink $tcachefile;
is(-f $cachefile, undef, "No cache file to end");
is(-f $tcachefile, undef, "No cache file to end");

File::Path::rmtree( $tmphtmldir, 0 );
ok(! (-d $tmphtmldir), "No temp html directory to start");