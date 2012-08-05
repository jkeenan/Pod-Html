package Pod::Html::Installhtml;
use strict;
require Exporter;

#use vars qw($VERSION @ISA @EXPORT_OK);
use vars qw($VERSION);
$VERSION = 1.16;
use Cwd;
use File::Basename qw( dirname );
use File::Spec::Functions qw(rel2abs no_upwards);
use Pod::Html;
use Pod::Html::Auxiliary qw(
    anchorify
    relativize_url
);

sub new {
    my $class = shift;
    my %args = (
        podpath     => [ '.' ],
        podroot     => '.',
        htmldir     => '',
        htmlroot    => '/',
        recurse     => 0,
        splithead   => [],
        splititem   => [],
        splitpod    => '',
        verbose     => 0,
    );
    return bless \%args, $class;
}

sub process_options {
    my ($self, $opts) = @_;

    # list of directories
    if (defined $opts->{podpath}) {
        my @podpaths = split(":", $opts->{podpath});
        die "'podpath' option, if used, must have non-zero number of colon-delimited directories"
            unless @podpaths;
        @{$self->{podpath}} = @podpaths;
    }

    # lists of files
    @{$self->{splithead}} = split(",", $opts->{splithead}) if defined $opts->{splithead};
    @{$self->{splititem}} = split(",", $opts->{splititem}) if defined $opts->{splititem};

    for my $r ( qw| htmldir htmlroot podroot splitpod recurse verbose | ) {
        $self->{$r} = $opts->{$r} if defined $opts->{$r};
    }

    @{$self->{ignore}} =
        map "$self->{podroot}/$_", split(",", $opts->{ignore})
            if defined $opts->{ignore};
}

sub cleanup_elements {
    my $self = shift;
    # set these variables to appropriate values if the user didn't specify
    #  values for them.
    $self->{htmldir}  = "$self->{htmlroot}/html" unless $self->{htmldir};
    $self->{splitpod} = "$self->{podroot}/pod" unless $self->{splitpod};
    
    # make sure that the destination directory exists
    if (! -d $self->{htmldir} ) {
        mkdir($self->{htmldir}, 0755)
            || die "$0: cannot make directory $self->{htmldir}: $!\n";
    }
}

sub split_on_head {
    my $self = shift;
    my($pod, $dirname, $filename);
    #   my @ignoredirs = ();

    # split the files specified in @splithead on =head[1-6] pod directives
    print "splitting files by head.\n"
        if $self->{verbose} && $#{$self->{splithead}} >= 0;
    foreach $pod (@{$self->{splithead}}) {
        # figure out the directory name and filename
        $pod      =~ s,^([^/]*)$,/$1,;
        $pod      =~ m,(.*)/(.*?)(\.pod)?$,;
        $dirname  = $1;
        $filename = "$2.pod";
    
        # since we are splitting this file it shouldn't be converted.
        push(@{$self->{ignore}}, "$self->{podroot}/$dirname/$filename");
    
        push(@{$self->{splitdirs}}, splitpod( {
            file        => "$self->{podroot}/$dirname/$filename",
            splitdirs   => $self->{splitdirs},
            verbose     => $self->{verbose},
        } ) );
    }
}

sub split_on_item {
    my $self = shift;
    my($pwd, $dirname, $filename);

    print "splitting files by item.\n"
        if $self->{verbose} && $#{$self->{splititem}} >= 0;
    $pwd = getcwd();
    my $splitter = rel2abs("$self->{splitpod}/splitpod", $pwd);
    my $perl = rel2abs($^X, $pwd);
    foreach my $pod (@{$self->{splititem}}) {
        # figure out the directory to split into
        $pod      =~ s,^([^/]*)$,/$1,;
        $pod      =~ m,(.*)/(.*?)(\.pod)?$,;
        $dirname  = "$1/$2";
        $filename = "$2.pod";
    
        # since we are splitting this file it shouldn't be converted.
        my $this_poddir = "$self->{podroot}/$dirname";
        push(@{$self->{ignore}}, "$this_poddir.pod");
    
        # split the pod
        push(@{$self->{splitdirs}}, $this_poddir);
        if (! -d $this_poddir) {
            mkdir($this_poddir, 0755) ||
                die "$0: error creating directory $this_poddir: $!\n";
        }
        chdir($this_poddir) ||
            die "$0: error changing to directory $this_poddir: $!\n";
        die "$splitter not found. Use '--splitpod dir' option.\n"
            unless -f $splitter;
        system($perl, $splitter, "../$filename") &&
            warn "$0: error running '$splitter ../$filename'"
             ." from $this_poddir";
    }
    chdir($pwd);
}

sub basic_installation {
    my $self = shift;
    foreach my $dir (@{$self->{podpath}}) {
        my $rv = $self->installdir( $dir );
    }
    return scalar(@{$self->{podpath}});
}

sub create_all_indices {
    my $self = shift;
    foreach my $dir (@{$self->{splititem}}) {
        print "creating index $self->{htmldir}/$dir.html\n"
            if $self->{verbose};
        $self->create_index($dir);
    }
    return scalar(@{$self->{splititem}});
}

sub handle_all_splits {
    my $self = shift;
    foreach my $dir (@{$self->{splithead}}) {
        (my $pod = $dir) =~ s,^.*/,,;
        $dir .= ".pod" unless $dir =~ /(\.pod|\.pm)$/;
        # let pod2html create the file
        my $rv = $self->runpod2html( {
          podfile         => $dir,
          doindex         => 1,
        } );
    
        # now go through and truncate after the index
        $dir =~ /^(.*?)(\.pod|\.pm)?$/sm;
        my $file = "$self->{htmldir}/$1";
        print "creating index $file.html\n" if $self->{verbose};
    
        # read in everything until what would have been the first =head
        # directive, patching the index as we go.
        open(my $H, '<', "$file.html") ||
            die "$0: error opening $file.html for input: $!\n";
        $/ = "";
        my @data = ();
        while (<$H>) {
            last if /name="name"/i;
            $_ =~ s{href="#(.*)">}{
                my $url = "$pod/$1.html" ;
                $url = relativize_url( $url, "$file.html" )
                if ( ! defined $self->{htmlroot} || $self->{htmlroot} eq '' );
                "href=\"$url\">" ;
            }egi;
            push @data, $_;
        }
        close($H);
    
        # now rewrite the file
        open(my $HOUT, '>', "$file.html") ||
            die "$0: error opening $file.html for output: $!\n";
            print $HOUT "@data", "\n";
        close($HOUT);
    }
    return 1;
}

# splitpod - splits a .pod file into several smaller .pod files
sub create_index {
    my ($self, $passed_dir) = @_;
    my $html = "$self->{htmldir}/$passed_dir.html";
    my $dir  = "$self->{htmldir}/$passed_dir";
    (my $pod = $dir) =~ s,^.*/,,;

    # get the list of .html files in this directory
    opendir(my $DIR, $dir) ||
        die "$0: error opening directory $dir for reading: $!\n";
    my @files = sort(grep(/\.html?$/, readdir($DIR)));
    closedir($DIR);

    open(my $HTML, '>', $html) ||
        die "$0: error opening $html for output: $!\n";

    # for each .html file in the directory, extract the index
    #    embedded in the file and throw it into the big index.
    print $HTML "<DL COMPACT>\n";
    foreach my $file (@files) {
    
        my $fullfile = "$dir/$file";
        my $filedata = do {
            open(my $IN, '<', $fullfile) ||
            die "$0: error opening $fullfile for input: $!\n";
            local $/ = undef;
            <$IN>;
            close $IN;
        };
    
        # pull out the NAME section
        my($lcp1, $lcp2) =
            ($filedata =~
            m#<h1 id="NAME">NAME</h1>\s*<p>\s*(\S+)\s+-\s+(\S.*?\S)</p>#);
        defined $lcp1 or die "$0: can't find NAME section in $fullfile\n";
    
        my $url= "$pod/$file" ;
        if ( ! defined $self->{htmlroot} || $self->{htmlroot} eq '' ) {
            $url = relativize_url( "$pod/$file", $html ) ;
        }
    
        print $HTML qq(<DT><A HREF="$url">);
        print $HTML "$lcp1</A></DT><DD>$lcp2</DD>\n";
    }
    print $HTML "</DL>\n";

    close($HTML);
}

#  where a new file is started each time a =head[1-6] pod directive
#  is encountered in the input file.

sub splitpod {
    my $args = shift;
    my $poddir = dirname($args->{file});
    my(@poddata, @filedata, @heads);
    my @splitdirs = ();

    print "splitting $args->{file}\n" if $args->{verbose};

    # read the file in paragraphs
    $/ = "";
    open(my $SPLITIN, '<', $args->{file}) ||
        die "$0: error opening $args->{file} for input: $!\n";
    @filedata = <$SPLITIN>;
    close($SPLITIN) ||
    die "$0: error closing $args->{file}: $!\n";

    # restore the file internally by =head[1-6] sections
    @poddata = ();
    my ($i, $j);
    for ($i = 0, $j = -1; $i <= $#filedata; $i++) {
        $j++ if ($filedata[$i] =~ /^\s*=head[1-6]/);
        if ($j >= 0) { 
            $poddata[$j]  = "" unless defined $poddata[$j];
            $poddata[$j] .= "\n$filedata[$i]" if $j >= 0;
        }
    }

    # create list of =head[1-6] sections so that we can rewrite
    #  L<> links as necessary.
    my %heads = ();
    for my $i (0..$#poddata) {
        $heads{anchorify($1)} = 1 if $poddata[$i] =~ /=head[1-6]\s+(.*)/;
    }

    # create a directory of a similar name and store all the
    #  files in there
    my $tmp = $args->{file};
    $tmp =~ s,.*/(.*),$1,;    # get the last part of the name
    my $dir = $tmp;
    $dir =~ s/\.pod//g;
    my $this_poddir = "$poddir/$dir";
    push(@splitdirs, $this_poddir);
    mkdir($this_poddir, 0755) ||
        die "$0: could not create directory $this_poddir: $!\n"
            unless -d $this_poddir;

    # for each section of the file create a separate pod file
    $poddata[0] =~ /^\s*=head[1-6]\s+(.*)/;
    my $section    = "";
    my $nextsec    = $1;
    my $prevsec;
    for (my $i = 0; $i <= $#poddata; $i++) {
        # determine the "prev" and "next" links
        $prevsec = $section;
        $section = $nextsec;
        if ($i < $#poddata) {
            $poddata[$i+1] =~ /^\s*=head[1-6]\s+(.*)/;
            $nextsec       = $1;
        } else {
            $nextsec = "";
        }
    
        # determine an appropriate filename (this must correspond with
        #  what pod2html will try and guess)
        # $poddata[$i] =~ /^\s*=head[1-6]\s+(.*)/;
        my $thisfile = "$dir/" . anchorify($section) . ".pod";
    
        # create the new .pod file
        my $this_podfile = "$poddir/$thisfile";
        print "\tcreating $this_podfile\n" if $args->{verbose};
        open(my $SPLITOUT, '>', $this_podfile) ||
            die "$0: error opening $this_podfile for output: $!\n";
        $poddata[$i] =~ s,L<([^<>]*)>,
                defined $heads{anchorify($1)} ? "L<$dir/$1>" : "L<$1>"
                 ,ge;
        print $SPLITOUT $poddata[$i]."\n\n";
        print $SPLITOUT "=over 4\n\n";
        print $SPLITOUT "=item *\n\nBack to L<$dir/\"$prevsec\">\n\n"
            if $prevsec;
        print $SPLITOUT "=item *\n\nForward to L<$dir/\"$nextsec\">\n\n"
            if $nextsec;
        print $SPLITOUT "=item *\n\nUp to L<$dir>\n\n";
        print $SPLITOUT "=back\n\n";
        close($SPLITOUT) ||
            die "$0: error closing $this_podfile: $!\n";
    }
    return \@splitdirs;
}

# installdir - takes care of converting the .pod and .pm files in the
#  current directory to .html files and then installing those.

sub installdir {
    my ($self, $dir) = @_;

    my @dirlist; # directories to recurse on
    my @podlist; # .pod files to install
    my @pmlist;  # .pm files to install

    # should files in this directory get an index?
    my $doindex = (grep($_ eq "$self->{podroot}/$dir", @{$self->{splitdirs}}) ? 0 : 1);

    opendir(my $DIR, "$self->{podroot}/$dir")
        || die "$0: error opening directory $self->{podroot}/$dir: $!\n";

    while(readdir $DIR) {
        no_upwards($_) or next;
        my $is_dir = -d "$self->{podroot}/$dir/$_";
        next if $is_dir and not $self->{recurse};
        my $target = (
            $is_dir    ? \@dirlist :
            s/\.pod$// ? \@podlist :
            s/\.pm$//  ? \@pmlist  :
            undef
        );
        push @$target, "$dir/$_" if $target;
    }

    closedir($DIR);

    if ($^O eq 'VMS') { s/\.dir$//i for @dirlist }

    # recurse on all subdirectories we kept track of
    foreach my $dir (@dirlist) {
        my $rv = $self->installdir( $dir );
    }

    # install all the pods we found
    foreach my $pod (@podlist) {
        # check if we should ignore it.
        next if $pod =~ m(/t/); # comes from a test file
        next if grep($_ eq "$pod.pod", @{$self->{ignore}});
    
        # check if a .pm files exists too
        if (grep($_ eq $pod, @pmlist)) {
            print  "$0: Warning both '$self->{podroot}/$pod.pod' and "
            . "'$self->{podroot}/$pod.pm' exist, using pod\n";
            push(@{$self->{ignore}}, "$pod.pm");
        }
        my $rv = $self->runpod2html( {
          podfile         => "$pod.pod",
          doindex         => $doindex,
        } );
    }

    # install all the .pm files we found
    foreach my $pm (@pmlist) {
        # check if we should ignore it.
        next if $pm =~ m(/t/); # comes from a test file
        next if grep($_ eq "$pm.pm", @{$self->{ignore}});
    
        my $rv = $self->runpod2html( {
          podfile         => "$pm.pm",
          doindex         => $doindex,
        } );
    }
}

# runpod2html - invokes pod2html to convert a .pod or .pm file to a .html
#  file.
# $rv = runpod2html( {
#   podfile         => $pod,
#   doindex         => $doindex,
# } );
#
sub runpod2html {
    my ($self, $args) = @_;
    my($html, $i, $dir, @dirs);

    $html = $args->{podfile};
    $html =~ s/\.(pod|pm)$/.html/g;

    # make sure the destination directories exist
    @dirs = split("/", $html);
    $dir  = "$self->{htmldir}/";
    for ($i = 0; $i < $#dirs; $i++) {
        if (! -d "$dir$dirs[$i]") {
            mkdir("$dir$dirs[$i]", 0755) ||
            die "$0: error creating directory $dir$dirs[$i]: $!\n";
        }
        $dir .= "$dirs[$i]/";
    }

    # invoke pod2html
    print "$self->{podroot}/$args->{podfile} => $self->{htmldir}/$html\n"
        if $self->{verbose};
    my $p2h = Pod::Html->new();
    my $options = {
        htmldir     => $self->{htmldir},
        htmlroot    => $self->{htmlroot},
        podpath     => join(":", @{$self->{podpath}}),
        podroot     => $self->{podroot},
        header      => 1,
        index       => ($args->{doindex} ? 1 : 0),
        recurse     => ($self->{recurse} ? 1 : 0),
        infile      => "$self->{podroot}/$args->{podfile}",
        outfile     => "$self->{htmldir}/$html",
    };
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    $p2h->generate_pages_cache();
    
    my $parser = $p2h->prepare_parser();
    $p2h->prepare_html_components($parser);

    my $output = $p2h->prepare_output($parser);
    my $rv = $p2h->write_html($output);
    die "$0: error running pod2html: $!\n" if $?;
    return $rv;
}

sub get {
    my ($self, $param) = @_;
    die "get() must have defined argument: $!"
        unless defined $param;
    return $self->{$param} || undef;
}

1;
