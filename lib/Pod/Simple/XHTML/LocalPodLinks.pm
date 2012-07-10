package Pod::Simple::XHTML::LocalPodLinks;
use strict;
use warnings;
use base 'Pod::Simple::XHTML';

use File::Spec;
use File::Spec::Unix;
use lib ( './lib' );
use Pod::Html::Auxiliary qw(
    unixify
    relativize_url
);


__PACKAGE__->_accessorize(
 'htmldir',
 'htmlfileurl',
 'htmlroot',
 'pages', # Page name => relative/path/to/page from root POD dir
 'quiet',
 'verbose',
);

#sub resolve_pod_page_link {
#    my ($self, $to, $section) = @_;
#
#    return undef unless defined $to || defined $section;
#    if (defined $section) {
#        $section = '#' . $self->idify($section, 1);
#        return $section unless defined $to;
#    } else {
#        $section = '';
#    }
#
#    my $path; # path to $to according to %Pages
#    unless (exists $self->pages->{$to}) {
#        # Try to find a POD that ends with $to and use that.
#        # e.g., given L<XHTML>, if there is no $Podpath/XHTML in %Pages,
#        # look for $Podpath/*/XHTML in %Pages, with * being any path,
#        # as a substitute (e.g., $Podpath/Pod/Simple/XHTML)
#        my @matches;
#        foreach my $modname (keys %{$self->pages}) {
#            push @matches, $modname if $modname =~ /::\Q$to\E\z/;
#        }
#
#        if ($#matches == -1) {
#            warn "Cannot find \"$to\" in podpath: " . 
#                 "cannot find suitable replacement path, cannot resolve link\n"
#                 unless $self->quiet;
#            return '';
#        } elsif ($#matches == 0) {
#            warn "Cannot find \"$to\" in podpath: " .
#                 "using $matches[0] as replacement path to $to\n" 
#                 unless $self->quiet;
#            $path = $self->pages->{$matches[0]};
#        } else {
#            warn "Cannot find \"$to\" in podpath: " .
#                 "more than one possible replacement path to $to, " .
#                 "using $matches[-1]\n" unless $self->quiet;
#            # Use [-1] so newer (higher numbered) perl PODs are used
#            $path = $self->pages->{$matches[-1]};
#        }
#    } else {
#        $path = $self->pages->{$to};
#    }
#
#    my $url = File::Spec::Unix->catfile(unixify($self->htmlroot),
#                                        $path);
#
#    if ($self->htmlfileurl ne '') {
#        # then $self->htmlroot eq '' (by definition of htmlfileurl) so
#        # $self->htmldir needs to be prepended to link to get the absolute path
#        # that will be relativized
#        $url = relativize_url(
#            File::Spec::Unix->catdir(unixify($self->htmldir), $url),
#            $self->htmlfileurl # already unixified
#        );
#    }
#
#    return $url . ".html$section";
#}

#

1;

