# -*- perl -*-
use strict;
use Pod::Html::Auxiliary qw( usage );
use Test::More tests => 3;

{
    local $@ = undef;
    eval { usage(); };
    like($@, qr/Usage:\s+$0\s+--help/s,
        "Got expected help output for usage() with no arguments");
}

{
    local $@ = undef;
    my $msg = "some warning message" ;
    my $warning_seen = '';
    local $SIG{__WARN__} = sub { $warning_seen = $_[0]; };
    eval { usage( '-', $msg ); };
    like($warning_seen, qr/$msg/, "Got expected warning");
    like($@, qr/Usage:\s+$0\s+--help/s,
        "Got expected help output for usage() with no arguments");
}
