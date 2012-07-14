package Pod::Html;
use strict;
use vars qw( $VERSION );
$VERSION = 1.16;

use Carp;
use Config;
use Cwd;
use File::Basename qw( fileparse );
use File::Spec;
use Pod::Simple::Search;
use lib ( './lib' );
use Pod::Simple::XHTML::LocalPodLinks;
use Pod::Html::Auxiliary qw(
    html_escape
    unixify
);
use locale; # make \w work right in non-ASCII lands

=head1 NAME

Pod::Html - module to convert pod files to HTML

=head1 SYNOPSIS

    use Pod::Html;
    use Pod::Html::Auxiliary qw( parse_command_line );
    
    $p2h = Pod::Html->new();
    $p2h->process_options( parse_command_line() );
    $p2h->cleanup_elements();
    $p2h->generate_pages_cache();
    
    $parser = $p2h->prepare_parser();
    $p2h->prepare_html_components($parser);

    $output = $p2h->prepare_output($parser);
    $rv = $p2h->write_html($output);

=head1 DESCRIPTION

Pod::Html is the backend for the F<pod2html> utility.  You may continue to run
the F<pod2html> utility as you have always done.

    pod2html --help --htmlroot=<name> --infile=<name> --outfile=<name>
             --podpath=<name>:...:<name> --podroot=<name>
             --recurse --norecurse --verbose
             --index --noindex --title=<name>

However, Pod::Html itself now has an object-oriented interface rather than
one, all-inclusive function.  A Pod::Html object is constructed, then provided
with a hash of options which may be the result of parsing a command-line via
C<Pod::Html::Auxiliary::parse_command_line()>.  The data in the Pod::Html
object are fine-tuned.  Then, a parser is created based on Pod::Simple::XHTML.
That parser is then used to parse the input and write the HTML output.  (While
the input is typically a file containing text in Perl's Plain Old
Documentation format (POD) and the output is typically a file in F<.html>
format, the module will accept C<STDIN> and C<STDOUT>.)

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Pod::Html constructor.

=item * Arguments

    $p2h = Pod::Html->new();

None.

=item * Return Value

Pod::Html object.

=item * Comment

Sets default values for elements in the object.

=back

=cut

sub new {
    my $class = shift;
    my %args = ();
    $args{Curdir} = File::Spec->curdir;
    $args{Cachedir} = ".";   # The directory to which directory caches
                                #   will be written.
    $args{Dircache} = "pod2htmd.tmp";
    $args{Htmlroot} = "/";   # http-server base directory from which all
                                #   relative paths in $podpath stem.
    $args{Htmldir} = "";     # The directory to which the html pages
                                #   will (eventually) be written.
    $args{Htmlfile} = "";    # write to stdout by default
    $args{Htmlfileurl} = ""; # The url that other files would use to
                                # refer to this file.  This is only used
                                # to make relative urls that point to
                                # other files.

    $args{Poderrors} = 1;
    $args{Podfile} = "";              # read from stdin by default
    $args{Podpath} = [];
    $args{Podroot} = $args{Curdir};         # filesystem base directory from which all
                                #   relative paths in $podpath stem.
    $args{Css} = '';                  # Cascading style sheet
    $args{Recurse} = 1;               # recurse on subdirectories in $podpath.
    $args{Quiet} = 0;                 # not quiet by default
    $args{Verbose} = 0;               # not verbose by default
    $args{Doindex} = 1;               # non-zero if we should generate an index
    $args{Backlink} = 0;              # no backlinks added by default
    $args{Header} = 0;                # produce block header/footer
    $args{Title} = '';                # title to give the pod(s)
    $args{Saved_Cache_Key} = undef;
    return bless \%args, $class;
}

=head2 C<()>

=over 4

=item * Purpose

Accept list of options from external source and have them override default
values in object as needed.

=item * Arguments

    $p2h->process_options($opts);

Hash reference. Example of C<$opts>:

    $opts = {
        podfile => 't/feature.pod',
        outfile  => 't/feature.html',
        podpath => 'scooby:shaggy:fred:velma:daphne',
        podroot => '/path/to//current/directory',
    };

=item * Return Value

True value upon success.

=item * Comment

Typically (as in F<bin/pod2html>), the hash reference provided as the argument
will be the result of a call to C<Pod::Html::Auxiliary::parse_command_line()>,
which is in turn a wrapper around C<Getopt::Long::GetOptions()>.

Note: the C<libpods> option has been deprecated and a warning will be emitted
if its use is attempted.

=back

=cut

sub process_options {
    my ($self, $opts) = @_;
    if (defined $opts) {
        croak "process_options() needs hashref" unless ref($opts) eq 'HASH';
    }
    else {
        $opts = {};
    }
    # Declare intermediate hash to hold cleaned-up options
    my %h = ();
    @{$h{Podpath}}  = split(":", $opts->{podpath}) if defined $opts->{podpath};
    warn "--libpods is no longer supported" if defined $opts->{libpods};

    $h{Backlink}  =         $opts->{backlink}   if defined $opts->{backlink};
    $h{Cachedir}  = unixify($opts->{cachedir})  if defined $opts->{cachedir};
    $h{Css}       =         $opts->{css}        if defined $opts->{css};
    $h{Header}    =         $opts->{header}     if defined $opts->{header};
    $h{Htmldir}   = unixify($opts->{htmldir})   if defined $opts->{htmldir};
    $h{Htmlroot}  = unixify($opts->{htmlroot})  if defined $opts->{htmlroot};
    $h{Doindex}   =         $opts->{index}      if defined $opts->{index};
    $h{Podfile}   = unixify($opts->{infile})    if defined $opts->{infile};
    $h{Htmlfile}  = unixify($opts->{outfile})   if defined $opts->{outfile};
    $h{Poderrors} =         $opts->{poderrors}  if defined $opts->{poderrors};
    $h{Podroot}   = unixify($opts->{podroot})   if defined $opts->{podroot};
    $h{Quiet}     =         $opts->{quiet}      if defined $opts->{quiet};
    $h{Recurse}   =         $opts->{recurse}    if defined $opts->{recurse};
    $h{Title}     =         $opts->{title}      if defined $opts->{title};
    $h{Verbose}   =         $opts->{verbose}    if defined $opts->{verbose};
    $h{flush}     =         $opts->{flush}      if defined $opts->{flush};

    while (my ($k,$v) = each %h) {
        $self->{$k} = $v;
    };
    return 1;
}

=head2 C<cleanup_elements()>

=over 4

=item * Purpose

Makes corrections as needed to data in object.

=item * Arguments

    $p2h->cleanup_elements();

None.

=item * Return Value

True value upon success.

=item * Comment

If C<flush> option is set, caches are cleared.

The C<htmlroot> and C<htmldir> options are mutually exclusive.  If at this
point both have true values, the program dies and the user is instructed to
choose one or the other.

If a value has been provided for the C<title> option, that value is
HTML-escaped.

=back

=cut

sub cleanup_elements {
    my $self = shift;
    warn "Flushing directory caches\n"
        if $self->{Verbose} && defined $self->{flush};
    $self->{Dircache} = "$self->{Cachedir}/pod2htmd.tmp";
    if (defined $self->{flush}) {
        1 while unlink($self->{Dircache});
    }
    # prevent '//' in urls
    $self->{Htmlroot} = "" if $self->{Htmlroot} eq "/";
    $self->{Htmldir} =~ s#/\z##;
    # Per documentation, Htmlroot and Htmldir cannot both be set to true
    # values.  Die if that is the case.
    my $msg = "htmlroot and htmldir cannot both be set to true values\n";
    $msg .= "Choose one of the other";
    croak $msg if ($self->{Htmlroot} and $self->{Htmldir});


    if (  $self->{Htmlroot} eq ''
       && $self->{Htmldir} ne ''
       && substr( $self->{Htmlfile}, 0, length( $self->{Htmldir} ) ) eq $self->{Htmldir}
       ) {
        # Set the 'base' url for this file, so that we can use it
        # as the location from which to calculate relative links
        # to other files. If this is '', then absolute links will
        # be used throughout.
        # $self->{Htmlfileurl} =
        #   "$self->{Htmldir}/" . substr( $self->{Htmlfile}, length( $self->{Htmldir} ) + 1);
        # Is the above not just "$self->{Htmlfileurl} = $self->{Htmlfile}"?
        $self->{Htmlfileurl} = unixify($self->{Htmlfile});
    }

    # XXX: implement default title generator in pod::simple::xhtml
    # copy the way the old Pod::Html did it
    $self->{Title} = html_escape($self->{Title});
    return 1;
}

=head2 C<generate_pages_cache()>

=over 4

=item * Purpose

=item * Arguments

    $p2h->generate_pages_cache();

None.

=item * Return Value

True value upon success.

=item * Comment

=back

=cut

sub generate_pages_cache {
    my $self = shift;
    my $cache_tests = $self->get_cache();
    return if $cache_tests;

    # generate %{$self->{Pages}}
    my $pwd = getcwd();
    chdir($self->{Podroot}) || 
        die "$0: error changing to directory $self->{Podroot}: $!\n";

    # find all pod modules/pages in podpath, store in %{$self->{Pages}}
    # - callback used to remove Podroot and extension from each file
    # - laborious to allow '.' in dirnames (e.g., /usr/share/perl/5.14.1)
    my $name2path = Pod::Simple::Search->new->inc(0)->verbose($self->{Verbose})->laborious(1)->recurse($self->{Recurse})->survey(@{$self->{Podpath}});
    foreach my $modname (sort keys %{$name2path}) {
        $self->_save_page($name2path->{$modname}, $modname);
    }

    chdir($pwd) || die "$0: error changing to directory $pwd: $!\n";

    # cache the directory list for later use
    if ($self->{Verbose}) {
        warn "caching directories for later use\n";
    }
    open my $CACHE, '>', $self->{Dircache}
        or die "$0: error open $self->{Dircache} for writing: $!\n";

    my $cacheline = join(":", @{$self->{Podpath}}) . "\n$self->{Podroot}\n";
#    print STDERR "c: $cacheline";
    print $CACHE $cacheline;
    my $_updirs_only = ($self->{Podroot} =~ /\.\./) && !($self->{Podroot} =~ /[^\.\\\/]/);
    foreach my $key (keys %{$self->{Pages}}) {
        if($_updirs_only) {
          my $_dirlevel = $self->{Podroot};
          while($_dirlevel =~ /\.\./) {
            $_dirlevel =~ s/\.\.//;
            # Assume $self->{Pages}->{$key} has '/' separators (html dir separators).
            $self->{Pages}->{$key} =~ s/^[\w\s\-\.]+\///;
          }
        }
        my $keyline = "$key $self->{Pages}->{$key}\n";
#        print STDERR "k: $keyline";
        print $CACHE $keyline;
    }

    close $CACHE or die "error closing $self->{Dircache}: $!";
    return 1;
}

# Methods internal to generate_pages_cache()
#
# _save_page(): When a file containing POD is seen, cache its location inside
# the object.
sub _save_page {
    my ($self, $modspec, $modname) = @_;
#print STDERR "_sp args: $modspec | $modname\n";
    # Remove Podroot from path
    $modspec = ($self->{Podroot} eq File::Spec->curdir)
        ? File::Spec->abs2rel($modspec)
        : File::Spec->abs2rel(
            $modspec,
            File::Spec->canonpath($self->{Podroot})
          );

    # Convert path to unix style path
    $modspec = unixify($modspec);

    my ($file, $dir) = fileparse($modspec, qr/\.[^.]*/); # strip .ext
    my $value = $dir.$file;
#print STDERR "_sp return: $modname | $value\n";
    $self->{Pages}->{$modname} = $value;
}

# get_cache():  If a cache of POD files exists, use it.  Otherwise, start one.
sub get_cache {
    my $self = shift;

    # A first-level cache:
    # Don't bother reading the cache files if they still apply
    # and haven't changed since we last read them.

    my $this_cache_key = $self->cache_key();
    return 1 if (
        $self->{Saved_Cache_Key} and
        ($this_cache_key eq $self->{Saved_Cache_Key})
    );
    $self->{Saved_Cache_Key} = $this_cache_key;

    # load the cache of %{$self->{Pages}} if possible.  $tests will be
    # non-zero if successful.
    my $tests = 0;
    if (-f $self->{Dircache}) {
        if ($self->{Verbose}) {
            my $subr = (caller(0))[3];
            warn "$subr: scanning for directory cache\n";
        }
        $tests = $self->load_cache();
    }

    return $tests;
}

# cache_key(): Compose a key by which to search the cache file.
sub cache_key {
    my $self = shift;
    return join('!' => (
        $self->{Dircache},
        $self->{Recurse},
        @{$self->{Podpath}},
        $self->{Podroot},
        stat($self->{Dircache}),
    ) );
}

# load_cache(): Tries to determine the validity of the cache.  If so, it loads
# them and returns a non-zero value.
sub load_cache {
    my $self = shift;
    my $tests = 0;
    local $_;

    if ($self->{Verbose}) {
        my $subr = (caller(0))[3];
        warn "$subr: scanning for directory cache\n";
    }
    open(my $CACHEFH, '<', $self->{Dircache}) ||
        die "$0: error opening $self->{Dircache} for reading: $!\n";
    $/ = "\n";

    # is it the same podpath?
    $_ = <$CACHEFH>;
    chomp($_);
    $tests++ if (join(":", @{$self->{Podpath}}) eq $_);

    # is it the same podroot?
    $_ = <$CACHEFH>;
    chomp($_);
    $tests++ if ($self->{Podroot} eq $_);

    # load the cache if its good
    if ($tests != 2) {
        close($CACHEFH);
        return 0;
    }

    if ($self->{Verbose}) {
        my $subr = (caller(0))[3];
        warn "$subr: loading directory cache\n";
    }
    while (<$CACHEFH>) {
        /(.*?) (.*)$/;
        $self->{Pages}->{$1} = $2;
    }

    close($CACHEFH);
    return 1;
}

=head2 C<prepare_parser()>

=over 4

=item * Purpose

=item * Arguments

    $parser = $p2h->prepare_parser();

None.

=item * Return Value

Parser object.

=item * Comment

=back

=cut

sub prepare_parser {
    my $self = shift;
    # set options for the parser
    my $parser = Pod::Simple::XHTML::LocalPodLinks->new();
    $parser->codes_in_verbatim(0);
    $parser->anchor_items(1); # the old Pod::Html always did
    $parser->backlink($self->{Backlink}); # linkify =head1 directives
    $parser->htmldir($self->{Htmldir});
    $parser->htmlfileurl($self->{Htmlfileurl});
    $parser->htmlroot($self->{Htmlroot});
    $parser->index($self->{Doindex});
    $parser->no_errata_section(!$self->{Poderrors}); # note the inverse
    $parser->pages($self->{Pages});
    $parser->quiet($self->{Quiet});
    $parser->verbose($self->{Verbose});
    return $parser;
}

=head2 C<()>

=over 4

=item * Purpose

Composes parts of HTML such as header and footer.

=item * Arguments

    $p2h->prepare_html_components($parser);

Parser object which is return value of C<prepare_parser()>.

=item * Return Value

True value upon success.

=item * Comment

Internally modifies parser object.

=back

=cut

sub prepare_html_components {
    my ($self, $parser ) = @_;
    $parser->output_string(\my $output); # written to file later
    # We need to add this ourselves because we use our own header, not
    # ::XHTML's header. We need to set $parser->backlink to linkify
    # the =head1 directives
    my $bodyid = $self->{Backlink} ? ' id="_podtop_"' : '';

    my $csslink = '';
    my $bodystyle = ' style="background-color: white"';
    my $tdstyle = ' style="background-color: #cccccc"';

    if ($self->{Css}) {
        $csslink = qq(\n<link rel="stylesheet" href="$self->{Css}" type="text/css" />);
        $csslink =~ s,\\,/,g;
        $csslink =~ s,(/.):,$1|,;
        $bodystyle = '';
        $tdstyle= '';
    }

    # header/footer block
    my $block = $self->{Header} ? <<END_OF_BLOCK : '';
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_"$tdstyle valign="middle">
<big><strong><span class="_podblock_">&nbsp;$self->{Title}</span></strong></big>
</td></tr>
</table>
END_OF_BLOCK

    # create own header/footer because of --header
    $parser->html_header(<<"HTMLHEAD");
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$self->{Title}</title>$csslink
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:$Config{perladmin}" />
</head>

<body$bodyid$bodystyle>
$block
HTMLHEAD

    $parser->html_footer(<<"HTMLFOOT");
$block
</body>

</html>
HTMLFOOT
    return 1;
}

=head2 C<prepare_output($parser)>

=over 4

=item * Purpose

Compose HTML output.

=item * Arguments

    $output = $p2h->prepare_output($parser);

Parser object.

=item * Return Value

String holding output in HTML format.

=item * Comment

=back

=cut

sub prepare_output {
    my ($self, $parser) = @_;
    my $input;
#    unless (@ARGV && $ARGV[0]) {
        if ($self->{Podfile} and $self->{Podfile} ne '-') {
            $input = $self->{Podfile};
        }
#        else {
#            $input = '-'; # XXX: make a test case for this
#        }
#    } else {
#        $self->{Podfile} = $ARGV[0];
#        $input = *ARGV;
#    }

    if ($self->{Verbose}) {
        my $subr = (caller(0))[3];
        warn "$subr: Converting input file $self->{Podfile}\n";
    }
    $parser->output_string(\my $output); # written to file later
    $parser->parse_file($input);
    return $output;
}

=head2 C<write_html()>

=over 4

=item * Purpose

Final output of HTML to file (or C<STDOUT>).

=item * Arguments

    $rv = $p2h->write_html($output);

String which is return value of C<prepare_output()>.

=item * Return Value

True value upon success.  This indicates overall success of Pod::Html.

=item * Comment

=back

=cut

sub write_html {
    my ($self, $output) = @_;

    # Write output to file
    my $FHOUT;
    if ($self->{Htmlfile} and $self->{Htmlfile} ne '-') {
        open $FHOUT, ">", $self->{Htmlfile}
            or die "$0: cannot open $self->{Htmlfile} file for output: $!\n";
        binmode $FHOUT, ":utf8";
        print $FHOUT $output;
        close $FHOUT or die "Failed to close $self->{Htmlfile}: $!";
        chmod 0644, $self->{Htmlfile};
    }
    else {
        open $FHOUT, ">-";
        binmode $FHOUT, ":utf8";
        print $FHOUT $output;
        close $FHOUT or die "Failed to close handle to STDOUT: $!";
    }
    return 1;
}

=head2 C<get()>

=over 4

=item * Purpose

Access current value of an element in the Pod::Html object.

=item * Arguments

    my $ucachefile = $p2h->get('Dircache');

String holding name of element in object.

=item * Return Value

String holding value of element in object if a value is provided and if that
value is defined.  Otherwise, return value is undefined.

=item * Comment

Useful in testing of Pod::Html, but not needed in production programs.

=back

=cut

sub get {
    my ($self, $element) = @_;
    return unless defined $element;
    return unless (exists $self->{$element} and defined $self->{$element});
    return $self->{$element};
}

=head1 ENVIRONMENT

Uses C<$Config{pod2html}> to setup default options.

=head1 AUTHORS

Original version by Tom Christiansen, E<lt>tchrist@perl.comE<gt>.

Marc Green, E<lt>marcgreen@cpan.orgE<gt>. 

James E Keenan, E<lt>jkeenan@cpan.orgE<gt>.

=head1 SEE ALSO

L<perlpod>, L<pod2html>, L<Pod::Html::Auxiliary>.

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

1;

