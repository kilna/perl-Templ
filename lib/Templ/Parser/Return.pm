
package Templ::Parser::Return;
use base 'Templ::Parser';

use strict;
use warnings;

sub header { return 'my $templ_out = ';        }
sub append { return '$templ_out .= ';          }
sub footer { return ";\nreturn \$templ_out;\n" }

1;
