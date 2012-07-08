package Pod::Html;
use strict;
use vars qw( $VERSION );
$VERSION = 1.16;

use Carp;
#use Config;
use Cwd;
use File::Basename qw( fileparse );
use File::Spec;
#use File::Spec::Unix;
use Pod::Simple::Search;
use lib ( './lib' );
#use Pod::Simple::XHTML::LocalPodLinks;
use Pod::Html::Auxiliary qw(
    html_escape
    unixify
);
#    parse_command_line
#    usage
use locale; # make \w work right in non-ASCII lands

our %Pages;

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
    while (my ($k,$v) = each %{$options}) {
        $self->{$k} = $v;
    };
    return 1;
}

sub cleanup_elements {
    my $self = shift;
    warn "Flushing directory caches\n"
        if $self->{verbose} && defined $self->{flush};
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

sub generate_pages_cache {
    my $self = shift;
#    unless (get_cache($globals{Dircache}, $globals{Podpath},
#            $globals{Podroot}, $globals{Recurse}, $globals{Verbose})) {
        # generate %Pages
        my $pwd = getcwd();
        chdir($self->{Podroot}) || 
            die "$0: error changing to directory $self->{Podroot}: $!\n";

        # find all pod modules/pages in podpath, store in %Pages
        # - callback used to remove Podroot and extension from each file
        # - laborious to allow '.' in dirnames (e.g., /usr/share/perl/5.14.1)
#        Pod::Simple::Search->new->inc(0)->verbose($self->{Verbose})->laborious(1) ->callback(\&_save_page)->recurse($self->{Recurse})->survey(@{$self->{Podpath}});
        my $name2path = Pod::Simple::Search->new->inc(0)->verbose($self->{Verbose})->laborious(1)->recurse($self->{Recurse})->survey(@{$self->{Podpath}});
        foreach my $modname (sort keys %{$name2path}) {
            $self->_save_page($name2path->{$modname}, $modname);
        }

        chdir($pwd) || die "$0: error changing to directory $pwd: $!\n";

        # cache the directory list for later use
        warn "caching directories for later use\n" if $self->{Verbose};
        open my $CACHE, '>', $self->{Dircache}
            or die "$0: error open $self->{Dircache} for writing: $!\n";

        print $CACHE join(":", @{$self->{Podpath}}) . "\n$self->{Podroot}\n";
        my $_updirs_only = ($self->{Podroot} =~ /\.\./) && !($self->{Podroot} =~ /[^\.\\\/]/);
        foreach my $key (keys %Pages) {
            if($_updirs_only) {
              my $_dirlevel = $self->{Podroot};
              while($_dirlevel =~ /\.\./) {
                $_dirlevel =~ s/\.\.//;
                # Assume $Pages{$key} has '/' separators (html dir separators).
                $Pages{$key} =~ s/^[\w\s\-\.]+\///;
              }
            }
            print $CACHE "$key $Pages{$key}\n";
        }

        close $CACHE or die "error closing $self->{Dircache}: $!";
#    }
}

sub get {
    my ($self, $element) = @_;
    return unless defined $element;
    return unless (exists $self->{$element} and defined $self->{$element});
    return $self->{$element};
}

#
# store POD files in %Pages
#
sub _save_page {
#    my ($modspec, $modname) = @_;
    my ($self, $modspec, $modname) = @_;

    # Remove Podroot from path
    $modspec = $self->{Podroot} eq File::Spec->curdir
               ? File::Spec->abs2rel($modspec)
               : File::Spec->abs2rel($modspec,
                                     File::Spec->canonpath($self->{Podroot}));

    # Convert path to unix style path
    $modspec = unixify($modspec);

    my ($file, $dir) = fileparse($modspec, qr/\.[^.]*/); # strip .ext
    $Pages{$modname} = $dir.$file;
}


#sub get_cache {
#    my($dircache, $podpath, $podroot, $recurse, $verbose) = @_;
#
#    # A first-level cache:
#    # Don't bother reading the cache files if they still apply
#    # and haven't changed since we last read them.
#
#    my $this_cache_key = cache_key($dircache, $podpath, $podroot, $recurse);
#    return 1 if $globals{Saved_Cache_Key} and $this_cache_key eq $globals{Saved_Cache_Key};
#    $globals{Saved_Cache_Key} = $this_cache_key;
#
#    # load the cache of %Pages if possible.  $tests will be
#    # non-zero if successful.
#    my $tests = 0;
#    if (-f $dircache) {
#        if ($verbose) {
#            my $subr = (caller(0))[3];
#            warn "$subr: scanning for directory cache\n";
#        }
#        $tests = load_cache($dircache, $podpath, $podroot, $verbose);
#    }
#
#    return $tests;
#}
#
#sub cache_key {
#    my($dircache, $podpath, $podroot, $recurse) = @_;
#    return join('!',$dircache,$recurse,@$podpath,$podroot,stat($dircache));
#}
#
##
## load_cache - tries to find if the cache stored in $dircache is a valid
##  cache of %Pages.  if so, it loads them and returns a non-zero value.
##
#sub load_cache {
#    my($dircache, $podpath, $podroot, $verbose) = @_;
#    my $tests = 0;
#    local $_;
#
#    if ($verbose) {
#        my $subr = (caller(0))[3];
#        warn "$subr: scanning for directory cache\n";
#    }
#    open(my $CACHEFH, '<', $dircache) ||
#        die "$0: error opening $dircache for reading: $!\n";
#    $/ = "\n";
#
#    # is it the same podpath?
#    $_ = <$CACHEFH>;
#    chomp($_);
#    $tests++ if (join(":", @$podpath) eq $_);
#
#    # is it the same podroot?
#    $_ = <$CACHEFH>;
#    chomp($_);
#    $tests++ if ($podroot eq $_);
#
#    # load the cache if its good
#    if ($tests != 2) {
#        close($CACHEFH);
#        return 0;
#    }
#
#    if ($verbose) {
#        my $subr = (caller(0))[3];
#        warn "$subr: loading directory cache\n";
#    }
#    while (<$CACHEFH>) {
#        /(.*?) (.*)$/;
#        $Pages{$1} = $2;
#    }
#
#    close($CACHEFH);
#    return 1;
#}

=head1 NAME

Pod::Html - module to convert pod files to HTML

=cut

1;

