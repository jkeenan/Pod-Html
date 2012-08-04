package Pod::Html::Installhtml;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT_OK);
$VERSION = 1.16;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    new
    parse_command_line
    process_options
    cleanup_elements
    split_on_head
    split_on_item
    basic_installation
    create_all_indices
    handle_all_splits
);
use Cwd;
use File::Basename qw( dirname );
use File::Spec::Functions qw(rel2abs no_upwards);
use Getopt::Long;    # for command-line parsing
use Pod::Html;
use Pod::Html::Auxiliary qw(
    anchorify
    relativize_url
);

sub new {
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
    return \%args;
}

sub usage {
    warn "$0: @_\n" if @_;
    my $usage =<<END_OF_USAGE;
Usage: $0 --help --podpath=<name>:...:<name> --podroot=<name>
         --htmldir=<name> --htmlroot=<name> --norecurse --recurse
         --splithead=<name>,...,<name> --splititem=<name>,...,<name>
         --ignore=<name>,...,<name> --verbose

    --help      - this message
    --podpath   - colon-separated list of directories containing .pod and
                  .pm files to be converted (. by default).
    --podroot   - filesystem base directory from which all relative paths in
                  podpath stem (default is .).
    --htmldir   - directory to store resulting html files in relative
                  to the filesystem (\$podroot/html by default).
    --htmlroot  - http-server base directory from which all relative paths
                  in podpath stem (default is /).
    --norecurse - don't recurse on those subdirectories listed in podpath.
                  (default behavior).
    --recurse   - recurse on those subdirectories listed in podpath
    --splithead - comma-separated list of .pod or .pm files to split.  will
                  split each file into several smaller files at every occurrence
                  of a pod =head[1-6] directive.
    --splititem - comma-separated list of .pod or .pm files to split using
                  splitpod.
    --splitpod  - directory where the program splitpod can be found
                  (\$podroot/pod by default).
    --ignore    - comma-separated list of files that shouldn't be installed.
    --verbose   - self-explanatory.

END_OF_USAGE
    die $usage;
}

sub parse_command_line {
    my %opts = ();
    usage("") unless @ARGV;
    
    # Overcome shell's p1,..,p8 limitation.  
    # See vms/descrip_mms.template -> descrip.mms for invocation.
    if ( $^O eq 'VMS' ) { @ARGV = split(/\s+/,$ARGV[0]); }

    my $result = GetOptions( \%opts, qw(
        help
        podpath=s
        podroot=s
        htmldir=s
        htmlroot=s
        ignore=s
        recurse!
        splithead=s
        splititem=s
        splitpod=s
        verbose
    ));
    usage("invalid parameters") unless $result;
    my %parsed_args = ();
    usage() if defined $opts{help};
    $opts{help} = "";                 # make -w shut up
    return \%opts;
}

sub process_options {
    my ($args, $opts) = @_;

    my $parsed_args = {};
    while (my ($k,$v) = each %{$args}) {
        $parsed_args->{$k} = $v;
    }

    # list of directories
    @{$parsed_args->{podpath}}   = split(":", $opts->{podpath}) if defined $opts->{podpath};

    # lists of files
    @{$parsed_args->{splithead}} = split(",", $opts->{splithead}) if defined $opts->{splithead};
    @{$parsed_args->{splititem}} = split(",", $opts->{splititem}) if defined $opts->{splititem};

    for my $r ( qw| htmldir htmlroot podroot splitpod recurse verbose | ) {
        $parsed_args->{$r} = $opts->{$r} if defined $opts->{$r};
    }

    @{$parsed_args->{ignore}} =
        map "$parsed_args->{podroot}/$_", split(",", $opts->{ignore})
            if defined $opts->{ignore};
    return $parsed_args;
}

sub cleanup_elements {
    my $parsed_args = shift;
    # set these variables to appropriate values if the user didn't specify
    #  values for them.
    $parsed_args->{htmldir}  ||= "$parsed_args->{htmlroot}/html";
    $parsed_args->{splitpod} ||= "$parsed_args->{podroot}/pod";
    
    # make sure that the destination directory exists
    if (! -d $parsed_args->{htmldir} ) {
        mkdir($parsed_args->{htmldir}, 0755)
            || die "$0: cannot make directory $parsed_args->{htmldir}: $!\n";
    }
    return $parsed_args;
}

sub basic_installation {
    my $parsed_args = shift;
    foreach my $dir (@{$parsed_args->{podpath}}) {
        my $rv = installdir( {
          dir             => $dir,
          %{$parsed_args}
        } );
    }
    return scalar(@{$parsed_args->{podpath}});
}

sub create_all_indices {
    my $parsed_args = shift;
    foreach my $dir (@{$parsed_args->{splititem}}) {
        print "creating index $parsed_args->{htmldir}/$dir.html\n"
            if $parsed_args->{verbose};
        create_index($parsed_args, $dir);
    }
    return scalar(@{$parsed_args->{splititem}});
}

sub create_index {
    my ($parsed_args, $passed_dir) = @_;
    my $html = "$parsed_args->{htmldir}/$passed_dir.html";
    my $dir  = "$parsed_args->{htmldir}/$passed_dir";
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
#        if ( ! defined $Options{htmlroot} || $Options{htmlroot} eq '' ) {
        if ( ! defined $parsed_args->{htmlroot} || $parsed_args->{htmlroot} eq '' ) {
            $url = relativize_url( "$pod/$file", $html ) ;
        }
    
        print $HTML qq(<DT><A HREF="$url">);
        print $HTML "$lcp1</A></DT><DD>$lcp2</DD>\n";
    }
    print $HTML "</DL>\n";

    close($HTML);
}

sub handle_all_splits {
    my $parsed_args = shift;
    foreach my $dir (@{$parsed_args->{splithead}}) {
        (my $pod = $dir) =~ s,^.*/,,;
        $dir .= ".pod" unless $dir =~ /(\.pod|\.pm)$/;
        # let pod2html create the file
        my $rv = runpod2html( {
          podfile         => $dir,
          doindex         => 1,
          %{$parsed_args},
        } );
    
        # now go through and truncate after the index
        $dir =~ /^(.*?)(\.pod|\.pm)?$/sm;
        my $file = "$parsed_args->{htmldir}/$1";
        print "creating index $file.html\n" if $parsed_args->{verbose};
    
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
                if ( ! defined $parsed_args->{htmlroot} || $parsed_args->{htmlroot} eq '' );
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

sub split_on_head {
    my $args = shift;
    my($pod, $dirname, $filename);
    #   my @ignoredirs = ();

    # split the files specified in @splithead on =head[1-6] pod directives
    print "splitting files by head.\n"
        if $args->{verbose} && $#{$args->{splithead}} >= 0;
    foreach $pod (@{$args->{splithead}}) {
        # figure out the directory name and filename
        $pod      =~ s,^([^/]*)$,/$1,;
        $pod      =~ m,(.*)/(.*?)(\.pod)?$,;
        $dirname  = $1;
        $filename = "$2.pod";
    
        # since we are splitting this file it shouldn't be converted.
        push(@{$args->{ignoredirs}}, "$args->{podroot}/$dirname/$filename");
    
        push(@{$args->{splitdirs}}, splitpod( {
            file        => "$args->{podroot}/$dirname/$filename",
            splitdirs   => $args->{splitdirs},
            verbose     => $args->{verbose},
        } ) );
    }
    return $args;
}

sub split_on_item {
    my $args = shift;
    my($pwd, $dirname, $filename);

    print "splitting files by item.\n"
        if $args->{verbose} && $#{$args->{splititem}} >= 0;
    $pwd = getcwd();
    my $splitter = rel2abs("$args->{splitpod}/splitpod", $pwd);
    my $perl = rel2abs($^X, $pwd);
    foreach my $pod (@{$args->{splititem}}) {
        # figure out the directory to split into
        $pod      =~ s,^([^/]*)$,/$1,;
        $pod      =~ m,(.*)/(.*?)(\.pod)?$,;
        $dirname  = "$1/$2";
        $filename = "$2.pod";
    
        # since we are splitting this file it shouldn't be converted.
        my $this_poddir = "$args->{podroot}/$dirname";
        push(@{$args->{ignore}}, "$this_poddir.pod");
    
        # split the pod
        push(@{$args->{splitdirs}}, $this_poddir);
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
    return $args;
}

# splitpod - splits a .pod file into several smaller .pod files
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
    my $args = shift;

    my @dirlist; # directories to recurse on
    my @podlist; # .pod files to install
    my @pmlist;  # .pm files to install

    # should files in this directory get an index?
    my $doindex = (grep($_ eq "$args->{podroot}/$args->{dir}", @{$args->{splitdirs}}) ? 0 : 1);

    opendir(my $DIR, "$args->{podroot}/$args->{dir}")
        || die "$0: error opening directory $args->{podroot}/$args->{dir}: $!\n";

    while(readdir $DIR) {
        no_upwards($_) or next;
        my $is_dir = -d "$args->{podroot}/$args->{dir}/$_";
        next if $is_dir and not $args->{recurse};
        my $target = (
            $is_dir    ? \@dirlist :
            s/\.pod$// ? \@podlist :
            s/\.pm$//  ? \@pmlist  :
            undef
        );
        push @$target, "$args->{dir}/$_" if $target;
    }

    closedir($DIR);

    if ($^O eq 'VMS') { s/\.dir$//i for @dirlist }

    # recurse on all subdirectories we kept track of
    foreach my $dir (@dirlist) {
        my $rv = installdir( {
          dir             => $dir,
          recurse         => $args->{recurse},
          podroot         => $args->{podroot},
          splitdirs       => $args->{splitdirs},
          ignore          => $args->{ignore},
          htmldir         => $args->{htmldir},
          verbose         => $args->{verbose},
          htmlroot        => $args->{htmlroot},
          podpath         => $args->{podpath},
        } );
    }

    # install all the pods we found
    foreach my $pod (@podlist) {
        # check if we should ignore it.
        next if $pod =~ m(/t/); # comes from a test file
        next if grep($_ eq "$pod.pod", @{$args->{ignore}});
    
        # check if a .pm files exists too
        if (grep($_ eq $pod, @pmlist)) {
            print  "$0: Warning both '$args->{podroot}/$pod.pod' and "
            . "'$args->{podroot}/$pod.pm' exist, using pod\n";
            push(@{$args->{ignore}}, "$pod.pm");
        }
        my $rv = runpod2html( {
          podfile         => "$pod.pod",
          podroot         => $args->{podroot},
          podpath         => $args->{podpath},
          doindex         => $doindex,
          htmldir         => $args->{htmldir},
          htmlroot        => $args->{htmlroot},
          verbose         => $args->{verbose},
          recurse         => $args->{recurse},
        } );
    }

    # install all the .pm files we found
    foreach my $pm (@pmlist) {
        # check if we should ignore it.
        next if $pm =~ m(/t/); # comes from a test file
        next if grep($_ eq "$pm.pm", @{$args->{ignore}});
    
        my $rv = runpod2html( {
          podfile         => "$pm.pm",
          podroot         => $args->{podroot},
          podpath         => $args->{podpath},
          doindex         => $doindex,
          htmldir         => $args->{htmldir},
          htmlroot        => $args->{htmlroot},
          verbose         => $args->{verbose},
          recurse         => $args->{recurse},
        } );
    }
}

# runpod2html - invokes pod2html to convert a .pod or .pm file to a .html
#  file.
# $rv = runpod2html( {
#   podfile         => $pod,
#   podroot         => $podroot,
#   podpath         => \@podpath,
#   doindex         => $doindex,
#   htmldir         => $htmldir,
#   htmlroot        => $htmlroot,
#   verbose         => $verbose,
#   recurse         => $recurse,
# } );
#
sub runpod2html {
    my $args = shift;
    my($html, $i, $dir, @dirs);

    $html = $args->{podfile};
    $html =~ s/\.(pod|pm)$/.html/g;

    # make sure the destination directories exist
    @dirs = split("/", $html);
    $dir  = "$args->{htmldir}/";
    for ($i = 0; $i < $#dirs; $i++) {
        if (! -d "$dir$dirs[$i]") {
            mkdir("$dir$dirs[$i]", 0755) ||
            die "$0: error creating directory $dir$dirs[$i]: $!\n";
        }
        $dir .= "$dirs[$i]/";
    }

    # invoke pod2html
    print "$args->{podroot}/$args->{podfile} => $args->{htmldir}/$html\n"
        if $args->{verbose};
    my $p2h = Pod::Html->new();
    my $options = {
        htmldir     => $args->{htmldir},
        htmlroot    => $args->{htmlroot},
        podpath     => join(":", @{$args->{podpath}}),
        podroot     => $args->{podroot},
        header      => 1,
        index       => ($args->{doindex} ? 1 : 0),
        recurse     => ($args->{recurse} ? 1 : 0),
        infile      => "$args->{podroot}/$args->{podfile}",
        outfile     => "$args->{htmldir}/$html",
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

1;
