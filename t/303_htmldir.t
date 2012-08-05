#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    require "t/pod2html-lib.pl";
}

END {
    rem_test_dir();
}

use strict;
use Cwd;
use File::Spec;
use File::Spec::Functions;
use Test::More tests => 2;

SKIP: {
    my $output = make_test_dir();
    skip "$output", 2 if $output;

    my $cwd = cwd();
    my ($v, $d) = splitpath($cwd, 1);
    my $relcwd = substr($d, length(File::Spec->rootdir()));

    my $data_pos = tell DATA; # to read <DATA> twice

    TODO: {
        local $TODO = 'more mysterious';
    convert_n_test("htmldir3", "test --htmldir and --htmlroot 3a", 
        podpath => $relcwd,
        podroot => $v . File::Spec->rootdir,
        htmldir => catdir($cwd, 't', ''), # test removal trailing slash
        quiet => 1,
    );
    }

    seek DATA, $data_pos, 0; # to read <DATA> twice (expected output is the same)

    TODO: {
        local $TODO = "RT #114126: Test spuriously PASSes due to position in
        file\n";
        $TODO .= "Does not pass if first test in a file";
    convert_n_test("htmldir3", "test --htmldir and --htmlroot 3b", 
        podpath => catdir($relcwd, 't'),
        podroot => $v . File::Spec->rootdir,
        htmldir => 't',
        outfile => 't/htmldir3.html',
        quiet => 1,
    );
    }
}

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body style="background-color: white">



<ul id="index">
  <li><a href="#NAME">NAME</a></li>
  <li><a href="#LINKS">LINKS</a></li>
</ul>

<h1 id="NAME">NAME</h1>

<p>htmldir - Test --htmldir feature</p>

<h1 id="LINKS">LINKS</h1>

<p>Normal text, a <a>link</a> to nowhere,</p>

<p>a link to <a href="[RELCURRENTWORKINGDIRECTORY]/testdir/test.lib/var-copy.html">var-copy</a>,</p>

<p><a href="[RELCURRENTWORKINGDIRECTORY]/t/htmlescp.html">htmlescp</a>,</p>

<p><a href="[RELCURRENTWORKINGDIRECTORY]/t/feature.html#Another-Head-1">&quot;Another Head 1&quot; in feature</a>,</p>

<p>and another <a href="[RELCURRENTWORKINGDIRECTORY]/t/feature.html#Another-Head-1">&quot;Another Head 1&quot; in feature</a>.</p>


</body>

</html>


