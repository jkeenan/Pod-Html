package Pod::Html;
use strict;
use vars qw( $VERSION );
$VERSION = 1.16;

use Carp;
#use Config;
#use Cwd;
use File::Basename;
use File::Spec;
#use File::Spec::Unix;
#use Pod::Simple::Search;
use lib ( './lib' );
#use Pod::Simple::XHTML::LocalPodLinks;
use Pod::Html::Auxiliary qw(
    html_escape
);
#    parse_command_line
#    usage
#    unixify
use locale; # make \w work right in non-ASCII lands

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

sub process_options {
    my ($self, $options) = @_;
    if (defined $options) {
        croak "process_options() needs hashref" unless ref($options) eq 'HASH';
    }
    else {
        $options = {};
    }
    warn "Flushing directory caches\n"
        if $options->{verbose} && defined $options->{flush};
    $options->{Dircache} = "$options->{Cachedir}/pod2htmd.tmp";
    if (defined $options->{flush}) {
        1 while unlink($options->{Dircache});
    }
    while (my ($k,$v) = each %{$options}) {
        $self->{$k} = $v;
    };
    return 1;
}

sub cleanup_elements {
    my $self = shift;
    # prevent '//' in urls
    $self->{Htmlroot} = "" if $self->{Htmlroot} eq "/";
    $self->{Htmldir} =~ s#/\z##;

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

sub get {
    my ($self, $element) = @_;
    return unless defined $element;
    return unless (exists $self->{$element} and defined $self->{$element});
    return $self->{$element};
}

1;

__END__
=head1 NAME

Pod::Html - module to convert pod files to HTML

=head1 SYNOPSIS

    use Pod::Html;
    pod2html([options]);

=head1 DESCRIPTION

Converts files from pod format (see L<perlpod>) to HTML format.  It
can automatically generate indexes and cross-references, and it keeps
a cache of things it knows how to cross-reference.

=head1 FUNCTIONS

=head2 pod2html

    pod2html("pod2html",
             "--podpath=lib:ext:pod:vms",
             "--podroot=/usr/src/perl",
             "--htmlroot=/perl/nmanual",
             "--recurse",
             "--infile=foo.pod",
             "--outfile=/perl/nmanual/foo.html");

pod2html takes the following arguments:

=over 4

=item backlink

    --backlink

Turns every C<head1> heading into a link back to the top of the page.
By default, no backlinks are generated.

=item cachedir

    --cachedir=name

Creates the directory cache in the given directory.

=item css

    --css=stylesheet

Specify the URL of a cascading style sheet.  Also disables all HTML/CSS
C<style> attributes that are output by default (to avoid conflicts).

=item flush

    --flush

Flushes the directory cache.

=item header

    --header
    --noheader

Creates header and footer blocks containing the text of the C<NAME>
section.  By default, no headers are generated.

=item help

    --help

Displays the usage message.

=item htmldir

    --htmldir=name

Sets the directory to which all cross references in the resulting
html file will be relative. Not passing this causes all links to be
absolute since this is the value that tells Pod::Html the root of the 
documentation tree.

Do not use this and --htmlroot in the same call to pod2html; they are
mutually exclusive.

=item htmlroot

    --htmlroot=name

Sets the base URL for the HTML files.  When cross-references are made,
the HTML root is prepended to the URL.

Do not use this if relative links are desired: use --htmldir instead.

Do not pass both this and --htmldir to pod2html; they are mutually
exclusive.

=item index

    --index
    --noindex

Generate an index at the top of the HTML file.  This is the default
behaviour.

=item infile

    --infile=name

Specify the pod file to convert.  Input is taken from STDIN if no
infile is specified.

=item outfile

    --outfile=name

Specify the HTML file to create.  Output goes to STDOUT if no outfile
is specified.

=item poderrors

    --poderrors
    --nopoderrors

Include a "POD ERRORS" section in the outfile if there were any POD 
errors in the infile. This section is included by default.

=item podpath

    --podpath=name:...:name

Specify which subdirectories of the podroot contain pod files whose
HTML converted forms can be linked to in cross references.

=item podroot

    --podroot=name

Specify the base directory for finding library pods. Default is the
current working directory.

=item quiet

    --quiet
    --noquiet

Don't display I<mostly harmless> warning messages.  These messages
will be displayed by default.  But this is not the same as C<verbose>
mode.

=item recurse

    --recurse
    --norecurse

Recurse into subdirectories specified in podpath (default behaviour).

=item title

    --title=title

Specify the title of the resulting HTML file.

=item verbose

    --verbose
    --noverbose

Display progress messages.  By default, they won't be displayed.

=back

=head2 htmlify

    htmlify($heading);

Converts a pod section specification to a suitable section specification
for HTML. Note that we keep spaces and special characters except
C<", ?> (Netscape problem) and the hyphen (writer's problem...).

=head2 anchorify

    anchorify(@heading);

Similar to C<htmlify()>, but turns non-alphanumerics into underscores.  Note
that C<anchorify()> is not exported by default.

=head1 ENVIRONMENT

Uses C<$Config{pod2html}> to setup default options.

=head1 AUTHOR

Marc Green, E<lt>marcgreen@cpan.orgE<gt>. 

Original version by Tom Christiansen, E<lt>tchrist@perl.comE<gt>.

=head1 SEE ALSO

L<perlpod>

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

my %globals = ();
# associative array used to find the location
# of pages referenced by L<> links.
my %Pages = ();

sub init_globals {
    $globals{Curdir} = File::Spec->curdir;
    $globals{Cachedir} = ".";   # The directory to which directory caches
                                #   will be written.
    $globals{Dircache} = "pod2htmd.tmp";
    $globals{Htmlroot} = "/";   # http-server base directory from which all
                                #   relative paths in $podpath stem.
    $globals{Htmldir} = "";     # The directory to which the html pages
                                #   will (eventually) be written.
    $globals{Htmlfile} = "";    # write to stdout by default
    $globals{Htmlfileurl} = ""; # The url that other files would use to
                                # refer to this file.  This is only used
                                # to make relative urls that point to
                                # other files.

    $globals{Poderrors} = 1;
    $globals{Podfile} = "";              # read from stdin by default
    $globals{Podpath} = [];
    $globals{Podroot} = $globals{Curdir};         # filesystem base directory from which all
                                #   relative paths in $podpath stem.
    $globals{Css} = '';                  # Cascading style sheet
    $globals{Recurse} = 1;               # recurse on subdirectories in $podpath.
    $globals{Quiet} = 0;                 # not quiet by default
    $globals{Verbose} = 0;               # not verbose by default
    $globals{Doindex} = 1;               # non-zero if we should generate an index
    $globals{Backlink} = 0;              # no backlinks added by default
    $globals{Header} = 0;                # produce block header/footer
    $globals{Title} = '';                # title to give the pod(s)
    $globals{Saved_Cache_Key} = undef;
}

sub pod2html {
    local(@ARGV) = @_;
    local $_;

    init_globals();
    %globals = parse_command_line(%globals);
    %globals = _globals_cleanup(%globals);

    # load or generate/cache %Pages
    unless (get_cache($globals{Dircache}, $globals{Podpath},
            $globals{Podroot}, $globals{Recurse}, $globals{Verbose})) {
        # generate %Pages
        my $pwd = getcwd();
        chdir($globals{Podroot}) || 
            die "$0: error changing to directory $globals{Podroot}: $!\n";

        # find all pod modules/pages in podpath, store in %Pages
        # - callback used to remove Podroot and extension from each file
        # - laborious to allow '.' in dirnames (e.g., /usr/share/perl/5.14.1)
        Pod::Simple::Search->new->inc(0)->verbose($globals{Verbose})->laborious(1)
            ->callback(\&_save_page)->recurse($globals{Recurse})->survey(@{$globals{Podpath}});

        chdir($pwd) || die "$0: error changing to directory $pwd: $!\n";

        # cache the directory list for later use
        warn "caching directories for later use\n" if $globals{Verbose};
        open my $CACHE, '>', $globals{Dircache}
            or die "$0: error open $globals{Dircache} for writing: $!\n";

        print $CACHE join(":", @{$globals{Podpath}}) . "\n$globals{Podroot}\n";
        my $_updirs_only = ($globals{Podroot} =~ /\.\./) && !($globals{Podroot} =~ /[^\.\\\/]/);
        foreach my $key (keys %Pages) {
            if($_updirs_only) {
              my $_dirlevel = $globals{Podroot};
              while($_dirlevel =~ /\.\./) {
                $_dirlevel =~ s/\.\.//;
                # Assume $Pages{$key} has '/' separators (html dir separators).
                $Pages{$key} =~ s/^[\w\s\-\.]+\///;
              }
            }
            print $CACHE "$key $Pages{$key}\n";
        }

        close $CACHE or die "error closing $globals{Dircache}: $!";
    }

    # set options for the parser
    my $parser = Pod::Simple::XHTML::LocalPodLinks->new();
    $parser->codes_in_verbatim(0);
    $parser->anchor_items(1); # the old Pod::Html always did
    $parser->backlink($globals{Backlink}); # linkify =head1 directives
    $parser->htmldir($globals{Htmldir});
    $parser->htmlfileurl($globals{Htmlfileurl});
    $parser->htmlroot($globals{Htmlroot});
    $parser->index($globals{Doindex});
    $parser->no_errata_section(!$globals{Poderrors}); # note the inverse
    $parser->output_string(\my $output); # written to file later
    $parser->pages(\%Pages);
    $parser->quiet($globals{Quiet});
    $parser->verbose($globals{Verbose});

    # We need to add this ourselves because we use our own header, not
    # ::XHTML's header. We need to set $parser->backlink to linkify
    # the =head1 directives
    my $bodyid = $globals{Backlink} ? ' id="_podtop_"' : '';

    my $csslink = '';
    my $bodystyle = ' style="background-color: white"';
    my $tdstyle = ' style="background-color: #cccccc"';

    if ($globals{Css}) {
        $csslink = qq(\n<link rel="stylesheet" href="$globals{Css}" type="text/css" />);
        $csslink =~ s,\\,/,g;
        $csslink =~ s,(/.):,$1|,;
        $bodystyle = '';
        $tdstyle= '';
    }

    # header/footer block
    my $block = $globals{Header} ? <<END_OF_BLOCK : '';
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_"$tdstyle valign="middle">
<big><strong><span class="_podblock_">&nbsp;$globals{Title}</span></strong></big>
</td></tr>
</table>
END_OF_BLOCK

    # create own header/footer because of --header
    $parser->html_header(<<"HTMLHEAD");
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$globals{Title}</title>$csslink
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

    my $input;
    unless (@ARGV && $ARGV[0]) {
        if ($globals{Podfile} and $globals{Podfile} ne '-') {
            $input = $globals{Podfile};
        } else {
            $input = '-'; # XXX: make a test case for this
        }
    } else {
        $globals{Podfile} = $ARGV[0];
        $input = *ARGV;
    }

    if ($globals{Verbose}) {
        my $subr = (caller(0))[3];
        warn "$subr: Converting input file $globals{Podfile}\n";
    }
    $parser->parse_file($input);

    # Write output to file
    my $FHOUT;
    if ($globals{Htmlfile} and $globals{Htmlfile} ne '-') {
        open $FHOUT, ">", $globals{Htmlfile}
            or die "$0: cannot open $globals{Htmlfile} file for output: $!\n";
        binmode $FHOUT, ":utf8";
        print $FHOUT $output;
        close $FHOUT or die "Failed to close $globals{Htmlfile}: $!";
        chmod 0644, $globals{Htmlfile};
    }
    else {
        open $FHOUT, ">-";
        binmode $FHOUT, ":utf8";
        print $FHOUT $output;
        close $FHOUT or die "Failed to close handle to STDOUT: $!";
    }
}

##############################################################################

sub get_cache {
    my($dircache, $podpath, $podroot, $recurse, $verbose) = @_;

    # A first-level cache:
    # Don't bother reading the cache files if they still apply
    # and haven't changed since we last read them.

    my $this_cache_key = cache_key($dircache, $podpath, $podroot, $recurse);
    return 1 if $globals{Saved_Cache_Key} and $this_cache_key eq $globals{Saved_Cache_Key};
    $globals{Saved_Cache_Key} = $this_cache_key;

    # load the cache of %Pages if possible.  $tests will be
    # non-zero if successful.
    my $tests = 0;
    if (-f $dircache) {
        if ($verbose) {
            my $subr = (caller(0))[3];
            warn "$subr: scanning for directory cache\n";
        }
        $tests = load_cache($dircache, $podpath, $podroot, $verbose);
    }

    return $tests;
}

sub cache_key {
    my($dircache, $podpath, $podroot, $recurse) = @_;
    return join('!',$dircache,$recurse,@$podpath,$podroot,stat($dircache));
}

#
# load_cache - tries to find if the cache stored in $dircache is a valid
#  cache of %Pages.  if so, it loads them and returns a non-zero value.
#
sub load_cache {
    my($dircache, $podpath, $podroot, $verbose) = @_;
    my $tests = 0;
    local $_;

    if ($verbose) {
        my $subr = (caller(0))[3];
        warn "$subr: scanning for directory cache\n";
    }
    open(my $CACHEFH, '<', $dircache) ||
        die "$0: error opening $dircache for reading: $!\n";
    $/ = "\n";

    # is it the same podpath?
    $_ = <$CACHEFH>;
    chomp($_);
    $tests++ if (join(":", @$podpath) eq $_);

    # is it the same podroot?
    $_ = <$CACHEFH>;
    chomp($_);
    $tests++ if ($podroot eq $_);

    # load the cache if its good
    if ($tests != 2) {
        close($CACHEFH);
        return 0;
    }

    if ($verbose) {
        my $subr = (caller(0))[3];
        warn "$subr: loading directory cache\n";
    }
    while (<$CACHEFH>) {
        /(.*?) (.*)$/;
        $Pages{$1} = $2;
    }

    close($CACHEFH);
    return 1;
}



#
# htmlify - converts a pod section specification to a suitable section
# specification for HTML. Note that we keep spaces and special characters
# except ", ? (Netscape problem) and the hyphen (writer's problem...).
#
sub htmlify {
    my( $heading) = @_;
    $heading =~ s/(\s+)/ /g;
    $heading =~ s/\s+\Z//;
    $heading =~ s/\A\s+//;
    # The hyphen is a disgrace to the English language.
    # $heading =~ s/[-"?]//g;
    $heading =~ s/["?]//g;
    $heading = lc( $heading );
    return $heading;
}

#
# similar to htmlify, but turns non-alphanumerics into underscores
#
sub anchorify {
    my ($anchor) = @_;
    $anchor = htmlify($anchor);
    $anchor =~ s/\W/_/g;
    return $anchor;
}

#
# store POD files in %Pages
#
sub _save_page {
    my ($modspec, $modname) = @_;

    # Remove Podroot from path
    $modspec = $globals{Podroot} eq File::Spec->curdir
               ? File::Spec->abs2rel($modspec)
               : File::Spec->abs2rel($modspec,
                                     File::Spec->canonpath($globals{Podroot}));

    # Convert path to unix style path
    $modspec = unixify($modspec);

    my ($file, $dir) = fileparse($modspec, qr/\.[^.]*/); # strip .ext
    $Pages{$modname} = $dir.$file;
}

sub _globals_cleanup {
    my %globals = @_;
    # prevent '//' in urls
    $globals{Htmlroot} = "" if $globals{Htmlroot} eq "/";
    $globals{Htmldir} =~ s#/\z##;

    if (  $globals{Htmlroot} eq ''
       && $globals{Htmldir} ne ''
       && substr( $globals{Htmlfile}, 0, length( $globals{Htmldir} ) ) eq $globals{Htmldir}
       ) {
        # Set the 'base' url for this file, so that we can use it
        # as the location from which to calculate relative links
        # to other files. If this is '', then absolute links will
        # be used throughout.
        # $globals{Htmlfileurl} =
        #   "$globals{Htmldir}/" . substr( $globals{Htmlfile}, length( $globals{Htmldir} ) + 1);
        # Is the above not just "$globals{Htmlfileurl} = $globals{Htmlfile}"?
        $globals{Htmlfileurl} = unixify($globals{Htmlfile});
    }

    # XXX: implement default title generator in pod::simple::xhtml
    # copy the way the old Pod::Html did it
    $globals{Title} = html_escape($globals{Title});

    return %globals;
}

1;

