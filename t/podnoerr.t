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

$args = {
    podstub => "podnoerr",
    description => "pod error section",
    expect => $expect_raw,
    p2h => {
	    nopoderrors => 1,
    },
};
$args->{core} = 1 if $ENV{PERL_CORE};

xconvert($args);

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body>



<ul id="index">
  <li><a href="#NAME">NAME</a></li>
</ul>

<h1 id="NAME">NAME</h1>

<p>Test POD ERROR section</p>

<ul>

<p>This text is not allowed</p>

<p>*</p>

<p>The wiz item.</p>

<p>*</p>

<p>The waz item.</p>

</ul>


</body>

</html>


