# perl
use strict;
use warnings;
use Carp;
use Cwd;
use File::Spec::Functions qw(
    splitpath
    catdir
    catpath
);
use lib ( './lib' );
use Pod::Html qw( pod2html );
use Test::More qw(no_plan); # tests => 3;

my $podfile = 'feature';
my $cwd = Pod::Html::unixify( Cwd::cwd() );
my ($vol, $dir) = splitpath($cwd, 1);
my $relcwd = substr($dir, length(File::Spec->rootdir()));

my $new_dir  = catdir $dir, "t";
my $infile   = catpath $vol, $new_dir, "$podfile.pod";
my $htmldir = catdir($cwd, 't');
my $title = q{\'a title\'};

my $captured_html = "$htmldir/captured.html";
unlink $captured_html if (-e $captured_html);
#my @cmd = (
#    $^X,
#    '-Ilib',
#    '-MPod::Html',
#    '-e \'',
##    q{'Pod::Html::pod2html(},
##    qq{"--infile=$infile"},
##    qq{"--outfile=-"},
##    qq{"--backlink"},
##    qq{"--css=style.css"},
##    qq{"--header"}, # no styling b/c of --ccs
##    qq{"--htmldir=$htmldir"},
##    qq{"--noindex"},
##    qq{"--podpath=t"},
##    qq{"--podroot=$cwd"},
##    qq{"--title=$title"},
##    qq{"--quiet"},
##    qq{"--libpods=perlguts:perlootut"},
##    q{)'},
#    qq{print "hello world\n"},
#    q{'},
#    q{1>},
#    $captured_html,
#);
#print STDERR "@cmd\n";
#system(@cmd) and croak "Unable to divert to STDOUT";
my $cmd = qq{$^X -Ilib -mPod::Html -e '};
#$cmd .= qq{print "Hello world\n"};
$cmd .= qq{Pod::Html::pod2html(};
$cmd .= qq{"--infile=$infile" };
$cmd .= q{)};
$cmd .= q{'};
$cmd .= qq{ 1> $captured_html};
print STDERR "$cmd\n";
system($cmd) and croak "Unable to divert to STDOUT";
pass($0);

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>a title</title>
<link rel="stylesheet" href="style.css" type="text/css" />
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body id="_podtop_">
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_" valign="middle">
<big><strong><span class="_podblock_">&nbsp;a title</span></strong></big>
</td></tr>
</table>



<a href="#_podtop_"><h1 id="Head-1">Head 1</h1></a>

<p>A paragraph</p>



some html

<p>Another paragraph</p>

<a href="#_podtop_"><h1 id="Another-Head-1">Another Head 1</h1></a>

<p>some text and a link <a href="t/crossref.html">crossref</a></p>

<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_" valign="middle">
<big><strong><span class="_podblock_">&nbsp;a title</span></strong></big>
</td></tr>
</table>

</body>

</html>

__END__

#my @p2h_args = (
#    qq{"--backlink"},
#    qq{"--css=style.css"},
#    qq{"--header"}, # no styling b/c of --ccs
#    qq{"--htmldir=$htmldir"},
#    qq{"--noindex"},
#    qq{"--podpath=t"},
#    qq{"--podroot=$cwd"},
#    qq{"--title=a title"},
#    qq{"--quiet"},
#    qq{"--libpods=perlguts:perlootut"},
#);
