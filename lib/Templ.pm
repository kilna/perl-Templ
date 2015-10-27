package Templ;

use Exporter;
push @ISA, 'Exporter';
@EXPORT = qw(templ);

use strict;
use warnings;

our $VERSION = '0.02_01';

use Templ::Template;
sub templ (@) { Templ::Template->get( @_ ) }

1;
