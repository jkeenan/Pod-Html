Pod-Html
========

Fork of Pod-Html from Perl 5 blead

Pod::Html - module to convert pod files to HTML

Synopsis
========

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

Description
===========

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

