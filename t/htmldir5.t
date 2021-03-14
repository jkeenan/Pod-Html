# -*- perl -*-

BEGIN {
    use File::Spec::Functions ':ALL';
    @INC = $ENV{PERL_CORE}
        ? map { rel2abs($_) }
            (qw| ./lib ./t/lib ../../lib |)
        : map { rel2abs($_) }
            ( "ext/Pod-Html/lib", "ext/Pod-Html/t/lib", "./lib" );
}

use strict;
use warnings;
use Test::More tests => 1;
use Testing qw( xconvert setup_testing_dir );
use Cwd;

my $debug = 0;
my $startdir = cwd();
END { chdir($startdir) or die("Cannot change back to $startdir: $!"); }
my ($expect_raw, $args);
{ local $/; $expect_raw = <DATA>; }

my $tdir = setup_testing_dir( {
    startdir    => $startdir,
    debug       => $debug,
} );

my $cwd = catdir cwd(); # catdir converts path separators to that of the OS
                        # running the test
                        # XXX but why don't the other tests complain about
                        # this?

$args = {
    podstub => "htmldir5",
    description => "test --htmldir and --htmlroot 5",
    expect => $expect_raw,
    p2h => {
        podpath     => 't:testdir/test.lib',
        podroot     => $cwd,
        htmldir     => $cwd,
        htmlroot    => '/',
        quiet       => 1,
    },
    debug => $debug,
};
$args->{core} = 1 if $ENV{PERL_CORE};
xconvert($args);

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>htmldir - Test --htmldir feature</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body>



<ul id="index">
  <li><a href="#NAME">NAME</a></li>
  <li><a href="#LINKS">LINKS</a></li>
</ul>

<h1 id="NAME">NAME</h1>

<p>htmldir - Test --htmldir feature</p>

<h1 id="LINKS">LINKS</h1>

<p>Normal text, a <a>link</a> to nowhere,</p>

<p>a link to <a href="../testdir/test.lib/var-copy.html">var-copy</a>,</p>

<p><a href="./htmlescp.html">htmlescp</a>,</p>

<p><a href="./feature.html#Another-Head-1">&quot;Another Head 1&quot; in feature</a>,</p>

<p>and another <a href="./feature.html#Another-Head-1">&quot;Another Head 1&quot; in feature</a>.</p>


</body>

</html>

