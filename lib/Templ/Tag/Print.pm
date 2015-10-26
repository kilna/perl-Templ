package Templ::Tag::Print;
use base 'Templ::Tag';

use strict;
use warnings;

sub perl {
    my $self   = shift;
    my $expr   = shift;
    my $indent = shift;
    my $append = shift; # 'print ' or '$templ_out .= '
    my $out = '';
    if ($indent) { $out .= "$append'$indent';\n"; }
    if ( $expr ne '' ) { $out .= "$append$expr;\n"; }
    return $out;
}

1;
