use strict;
use warnings;
use Pod::Html;
use Config;
use Test::More tests => 1;

my $out = $$ . '.html';
Pod::Html::pod2html("--infile=$0", "--outfile=$out");

my $admin = $Config{'perladmin'};

my $expected = <<"EXPECTED";
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>9385.pl - A testscript for bug #9385</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:$admin" />
</head>

<body style="background-color: white">


<!-- INDEX BEGIN -->
<div name="index">
<p><a name="__index__"></a></p>

<ul>

	<li><a href="#name">NAME</a></li>
	<ul>

		<li><a href="#testcase">TESTCASE</a></li>
	</ul>

</ul>

<hr name="index" />
</div>
<!-- INDEX END -->

<p>
</p>
<h1><a name="name">NAME</a></h1>
<p>9385.pl - A testscript for bug #9385</p>
<p>
</p>
<h2><a name="testcase">TESTCASE</a></h2>
<p>The following testcase shows the bug</p>
<p>in Pod::Html</p>
<tt>
<pre>
#include &lt;stdio.h&gt;

int main(int argc,char *argv[]) {

  printf("Hello World\\n");
  return 0;
}
</pre>
</tt>
this is a test line in
an HTML section of this Pod.

</body>

</html>
EXPECTED

my $check;

{
  local $/;
  open my $fh, '<', $out or die "Cannot open $out: $!";
  $check = <$fh>;
  close $fh;
}

$check =~ s/\r?\n/\n/g;
$expected =~ s/\r?\n/\n/g;

TODO: {
    # https://rt.perl.org/rt3/Ticket/Display.html?id=9385
    local $TODO =
        "RT #9385:  =begin html/=end html eats lines consisting of single newlines";

    is( $check, $expected,
        "=begin html/=end html no longer eats single newlines" );
}

1 while unlink $out;
1 while unlink "pod2htmd.tmp";
1 while unlink "pod2htmi.tmp";

=head1 NAME

t/9385_pod_html.t - A test script for bug #9385

=head2 TESTCASE

The following testcase shows the bug

in Pod::Html

=begin html

<tt>
<pre>
#include &lt;stdio.h&gt;

int main(int argc,char *argv[]) {

  printf("Hello World\n");
  return 0;
}
</pre>
</tt>

this is a test line in

an HTML section of this Pod.

=end html
