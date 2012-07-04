package Pod::Html::Auxiliary;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT_OK);
$VERSION = 1.16;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    parse_command_line
    usage
    unixify
);

#use Carp;
use Config;
use File::Spec;
use File::Spec::Unix;
use Getopt::Long;
use locale; # make \w work right in non-ASCII lands

sub parse_command_line {
    my %globals = @_;
    my ($opt_backlink,$opt_cachedir,$opt_css,$opt_flush,$opt_header,
        $opt_help,$opt_htmldir,$opt_htmlroot,$opt_index,$opt_infile,
        $opt_outfile,$opt_poderrors,$opt_podpath,$opt_podroot,
        $opt_quiet,$opt_recurse,$opt_title,$opt_verbose,$opt_libpods);

    unshift @ARGV, split ' ', $Config{pod2html} if $Config{pod2html};
    my $result = GetOptions(
                       'backlink!'  => \$opt_backlink,
                       'cachedir=s' => \$opt_cachedir,
                       'css=s'      => \$opt_css,
                       'flush'      => \$opt_flush,
                       'help'       => \$opt_help,
                       'header!'    => \$opt_header,
                       'htmldir=s'  => \$opt_htmldir,
                       'htmlroot=s' => \$opt_htmlroot,
                       'index!'     => \$opt_index,
                       'infile=s'   => \$opt_infile,
                       'libpods=s'  => \$opt_libpods, # deprecated
                       'outfile=s'  => \$opt_outfile,
                       'poderrors!' => \$opt_poderrors,
                       'podpath=s'  => \$opt_podpath,
                       'podroot=s'  => \$opt_podroot,
                       'quiet!'     => \$opt_quiet,
                       'recurse!'   => \$opt_recurse,
                       'title=s'    => \$opt_title,
                       'verbose!'   => \$opt_verbose,
    );
    usage("-", "invalid parameters") if not $result;

    usage("-") if defined $opt_help;    # see if the user asked for help
    $opt_help = "";                     # just to make -w shut-up.

    @{$globals{Podpath}}  = split(":", $opt_podpath) if defined $opt_podpath;
    warn "--libpods is no longer supported" if defined $opt_libpods;

    $globals{Backlink}  =          $opt_backlink   if defined $opt_backlink;
    $globals{Cachedir}  = unixify($opt_cachedir)  if defined $opt_cachedir;
    $globals{Css}       =          $opt_css        if defined $opt_css;
    $globals{Header}    =          $opt_header     if defined $opt_header;
    $globals{Htmldir}   = unixify($opt_htmldir)   if defined $opt_htmldir;
    $globals{Htmlroot}  = unixify($opt_htmlroot)  if defined $opt_htmlroot;
    $globals{Doindex}   =          $opt_index      if defined $opt_index;
    $globals{Podfile}   = unixify($opt_infile)    if defined $opt_infile;
    $globals{Htmlfile}  = unixify($opt_outfile)   if defined $opt_outfile;
    $globals{Poderrors} =          $opt_poderrors  if defined $opt_poderrors;
    $globals{Podroot}   = unixify($opt_podroot)   if defined $opt_podroot;
    $globals{Quiet}     =          $opt_quiet      if defined $opt_quiet;
    $globals{Recurse}   =          $opt_recurse    if defined $opt_recurse;
    $globals{Title}     =          $opt_title      if defined $opt_title;
    $globals{Verbose}   =          $opt_verbose    if defined $opt_verbose;

    warn "Flushing directory caches\n"
        if $opt_verbose && defined $opt_flush;
    $globals{Dircache} = "$globals{Cachedir}/pod2htmd.tmp";
    if (defined $opt_flush) {
        1 while unlink($globals{Dircache});
    }
    return %globals;
}

sub usage {
    my $podfile = shift;
    warn "$0: $podfile: @_\n" if @_;
    die <<END_OF_USAGE;
Usage:  $0 --help --htmlroot=<name> --infile=<name> --outfile=<name>
           --podpath=<name>:...:<name> --podroot=<name> --cachedir=<name>
           --recurse --verbose --index --norecurse --noindex

  --[no]backlink  - turn =head1 directives into links pointing to the top of
                      the page (off by default).
  --cachedir      - directory for the directory cache files.
  --css           - stylesheet URL
  --flush         - flushes the directory cache.
  --[no]header    - produce block header/footer (default is no headers).
  --help          - prints this message.
  --htmldir       - directory for resulting HTML files.
  --htmlroot      - http-server base directory from which all relative paths
                      in podpath stem (default is /).
  --[no]index     - generate an index at the top of the resulting html
                      (default behaviour).
  --infile        - filename for the pod to convert (input taken from stdin
                      by default).
  --outfile       - filename for the resulting html file (output sent to
                      stdout by default).
  --[no]poderrors - include a POD ERRORS section in the output if there were 
                      any POD errors in the input (default behavior).
  --podpath       - colon-separated list of directories containing library
                      pods (empty by default).
  --podroot       - filesystem base directory from which all relative paths
                      in podpath stem (default is .).
  --[no]quiet     - suppress some benign warning messages (default is off).
  --[no]recurse   - recurse on those subdirectories listed in podpath
                      (default behaviour).
  --title         - title that will appear in resulting html file.
  --[no]verbose   - self-explanatory (off by default).

END_OF_USAGE

}

sub unixify {
    my $full_path = shift;
    return '' unless $full_path;
    return $full_path if $full_path eq '/';

    my ($vol, $dirs, $file) = File::Spec->splitpath($full_path);
    my @dirs = $dirs eq File::Spec->curdir()
               ? (File::Spec::Unix->curdir())
               : File::Spec->splitdir($dirs);
    if (defined($vol) && $vol) {
        $vol =~ s/:$// if $^O eq 'VMS';
        $vol = uc $vol if $^O eq 'MSWin32';

        if( $dirs[0] ) {
            unshift @dirs, $vol;
        }
        else {
            $dirs[0] = $vol;
        }
    }
    unshift @dirs, '' if File::Spec->file_name_is_absolute($full_path);
    return $file unless scalar(@dirs);
    $full_path = File::Spec::Unix->catfile(File::Spec::Unix->catdir(@dirs),
                                           $file);
    $full_path =~ s|^\/|| if $^O eq 'MSWin32'; # C:/foo works, /C:/foo doesn't
    return $full_path;
}

1;
